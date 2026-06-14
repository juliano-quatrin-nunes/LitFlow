class Repertoire::Musics::CifraDocxController < ApplicationController
  before_action :set_music

  def show
    target_key = params[:key] || @music.original_key
    version = "v1"
    expected_fingerprint = Digest::SHA1.hexdigest("#{@music.content_json.to_json}-#{target_key}-#{version}")

    respond_to do |format|
      format.turbo_stream do
        if @music.cifra_fingerprint == expected_fingerprint && @music.cifra_docx.attached?
          # Cache hit: Broadcast the ready toast which triggers the download
          docx_url = helpers.rails_blob_path(@music.cifra_docx, disposition: "attachment", only_path: true)
          filename = "#{@music.title.parameterize}.docx"

          render turbo_stream: turbo_stream.append("toasts", partial: "shared/toasts/toast", locals: {
            title: "Pronto!",
            description: "O download do DOCX começou.",
            kind: "success",
            download_url: docx_url,
            filename: filename
          })
        else
          # Cache miss: Enqueue job and show "Gerando..." toast
          GenerateMusicCifraJob.perform_later(@music.id, target_key, format: :docx)

          render turbo_stream: turbo_stream.append("toasts", partial: "shared/toasts/toast", locals: {
            title: "Gerando DOCX...",
            description: "Aguarde um instante.",
            kind: "info"
          })
        end
      end
    end
  end

  private

  def set_music
    @author = Repertoire::Author.find_by!(slug: params[:author_slug])
    @music = @author.musics.find_by!(slug: params[:id])
  end
end

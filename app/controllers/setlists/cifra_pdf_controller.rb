class Setlists::CifraPdfController < ApplicationController
  before_action :set_setlist

  def show
    version = "v1"
    items_data = @setlist.items.order(:position).map do |item|
      { id: item.id, key: item.key, music_id: item.item_id, music_updated_at: item.item&.updated_at }
    end
    expected_fingerprint = Digest::SHA1.hexdigest("#{items_data.to_json}-#{version}")

    respond_to do |format|
      format.turbo_stream do
        if @setlist.cifra_fingerprint == expected_fingerprint && @setlist.cifra_pdf.attached?
          # Cache hit
          pdf_url = helpers.rails_blob_path(@setlist.cifra_pdf, disposition: "attachment", only_path: true)
          filename = "#{@setlist.name.parameterize}.pdf"

          render turbo_stream: turbo_stream.append("toasts", partial: "shared/toasts/toast", locals: {
            title: "Pronto!",
            description: "O download do PDF começou.",
            kind: "success",
            download_url: pdf_url,
            filename: filename
          })
        else
          # Cache miss
          GenerateSetlistCifraJob.perform_later(@setlist.id, format: :pdf)

          render turbo_stream: turbo_stream.append("toasts", partial: "shared/toasts/toast", locals: {
            title: "Gerando PDF...",
            description: "Aguarde um instante.",
            kind: "info"
          })
        end
      end
    end
  end

  private

  def set_setlist
    @setlist = Setlist.find(params[:setlist_id])
  end
end

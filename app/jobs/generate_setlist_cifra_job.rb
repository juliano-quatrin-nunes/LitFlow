class GenerateSetlistCifraJob < ApplicationJob
  queue_as :default

  PDF_CONTENT_TYPE = "application/pdf".freeze
  DOCX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document".freeze
  VERSION = "v1".freeze # Formatter version for fingerprinting

  def perform(setlist_id, options = {})
    @setlist = Setlist.find(setlist_id)
    @requested_format = options[:format]&.to_sym || :pdf

    expected = calculate_fingerprint
    
    # Check cache
    if @setlist.cifra_fingerprint == expected && @setlist.cifra_pdf.attached? && @setlist.cifra_docx.attached?
      broadcast_ready
      return
    end

    # 1. Prepare bulk payload
    songs_payload = @setlist.items.order(:position).map do |item|
      music = item.music
      next unless music

      target_key = item.key
      current_content = music.content_json
      
      if target_key.present? && music.original_key.present? && target_key != music.original_key
        current_content = Repertoire::TranspositionService.call(current_content, music.original_key, target_key)
      end

      formatted = Repertoire::CifraFormatterService.new(current_content).call
      
      {
        title: music.title,
        author: music.author_name,
        sections: formatted[:sections]
      }
    end.compact

    payload = { songs: songs_payload }

    # 2. Render PDF
    pdf_binary = Repertoire::MusicCifraRenderer.render_pdf(payload)
    @setlist.cifra_pdf.attach(
      io: StringIO.new(pdf_binary),
      filename: filename("pdf"),
      content_type: PDF_CONTENT_TYPE
    )

    # 3. Render DOCX
    docx_binary = Repertoire::MusicCifraRenderer.render_docx(payload)
    @setlist.cifra_docx.attach(
      io: StringIO.new(docx_binary),
      filename: filename("docx"),
      content_type: DOCX_CONTENT_TYPE
    )

    # 4. Update fingerprint
    @setlist.update_column(:cifra_fingerprint, expected)

    broadcast_ready
  end

  private

  def calculate_fingerprint
    items_data = @setlist.items.order(:position).map do |item|
      { id: item.id, key: item.key, music_id: item.item_id, music_updated_at: item.item&.updated_at }
    end
    Digest::SHA1.hexdigest("#{items_data.to_json}-#{VERSION}")
  end

  def filename(ext)
    "#{@setlist.name.parameterize || "setlist-#{@setlist.id}"}.#{ext}"
  end

  def broadcast_ready
    attachment = @requested_format == :docx ? @setlist.cifra_docx : @setlist.cifra_pdf
    download_url = Rails.application.routes.url_helpers.rails_blob_path(attachment, disposition: "attachment", only_path: true)
    ext = @requested_format.to_s

    @setlist.broadcast_append_to(
      @setlist,
      target: "toasts",
      partial: "shared/toasts/toast",
      locals: {
        title: "Cifra pronta!",
        description: "O download do #{ext.upcase} começou.",
        kind: "success",
        download_url: download_url,
        filename: filename(ext)
      }
    )
  end
end

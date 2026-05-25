class GenerateMusicCifraJob < ApplicationJob
  queue_as :default

  PDF_CONTENT_TYPE = "application/pdf".freeze
  DOCX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document".freeze
  VERSION = "v1".freeze # Formatter version for fingerprinting

  def perform(music_id, target_key, options = {})
    @music = Repertoire::Music.find(music_id)
    @target_key = target_key
    @requested_format = options[:format]&.to_sym || :pdf

    expected = calculate_fingerprint
    
    # Check cache
    if @music.cifra_fingerprint == expected && @music.cifra_pdf.attached? && @music.cifra_docx.attached?
      broadcast_ready
      return
    end

    # 1. Prepare payload from content_json
    current_content = @music.content_json
    if @target_key.present? && @music.original_key.present? && @target_key != @music.original_key
      current_content = Repertoire::TranspositionService.call(current_content, @music.original_key, @target_key)
    end

    # Format for rendering
    formatted = Repertoire::CifraFormatterService.new(current_content).call
    
    payload = {
      title: @music.title,
      author: @music.author_name,
      sections: formatted[:sections]
    }

    # 2. Render PDF
    pdf_binary = Repertoire::MusicCifraRenderer.render_pdf(payload)
    @music.cifra_pdf.attach(
      io: StringIO.new(pdf_binary),
      filename: filename("pdf"),
      content_type: PDF_CONTENT_TYPE
    )

    # 3. Render DOCX
    docx_binary = Repertoire::MusicCifraRenderer.render_docx(payload)
    @music.cifra_docx.attach(
      io: StringIO.new(docx_binary),
      filename: filename("docx"),
      content_type: DOCX_CONTENT_TYPE
    )

    # 4. Update fingerprint
    @music.update_column(:cifra_fingerprint, expected)

    broadcast_ready
  end

  private

  def calculate_fingerprint
    Digest::SHA1.hexdigest("#{@music.content_json.to_json}-#{@target_key}-#{VERSION}")
  end

  def filename(ext)
    "#{@music.slug || "music-#{@music.id}"}.#{ext}"
  end

  def broadcast_ready
    attachment = @requested_format == :docx ? @music.cifra_docx : @music.cifra_pdf
    download_url = Rails.application.routes.url_helpers.rails_blob_path(attachment, disposition: "attachment", only_path: true)
    ext = @requested_format.to_s

    Turbo::StreamsChannel.broadcast_append_to(
      stream_name,
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

  def stream_name
    "music_#{@music.id}"
  end
end

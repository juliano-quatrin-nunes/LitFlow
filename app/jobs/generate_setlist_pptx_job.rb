class GenerateSetlistPptxJob < ApplicationJob
  queue_as :default

  retry_on Slides::RenderError, attempts: 3, wait: :polynomially_longer do |job, error|
    job.send(:on_render_failure, error)
  end

  PPTX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.presentationml.presentation".freeze

  def perform(setlist_id)
    @setlist = Setlist.find(setlist_id)
    expected = Slides::Fingerprint.for_setlist(@setlist)

    return if @setlist.pptx_fingerprint == expected && @setlist.pptx.attached?

    slides = Slides::SetlistComposer.call(@setlist)
    binary = Slides::PptxRenderer.render_slides(slides)
    @setlist.pptx.purge if @setlist.pptx.attached?
    @setlist.pptx.attach(
      io: StringIO.new(binary),
      filename: pptx_filename,
      content_type: PPTX_CONTENT_TYPE
    )
    @setlist.update_column(:pptx_fingerprint, expected)

    broadcast_ready
  end

  private

  def on_render_failure(_error)
    @setlist ||= Setlist.find_by(id: arguments.first)
    return unless @setlist

    @setlist.update_column(:pptx_fingerprint, nil) if @setlist.pptx_fingerprint.present?
    broadcast_error
  end

  def pptx_filename
    base = @setlist.name.to_s.parameterize.presence || "setlist-#{@setlist.id}"
    "#{base}.pptx"
  end

  def broadcast_ready
    download_url = Rails.application.routes.url_helpers.rails_blob_path(@setlist.pptx, disposition: "attachment", only_path: true)

    Turbo::StreamsChannel.broadcast_append_to(
      stream_name,
      target: "toasts",
      partial: "shared/toasts/toast",
      locals: {
        title: "Pronto!",
        description: "O download do PPTX da celebração começou.",
        kind: "success",
        download_url: download_url,
        filename: pptx_filename
      }
    )
  end

  def broadcast_error
    Turbo::StreamsChannel.broadcast_append_to(
      stream_name,
      target: "toasts",
      partial: "shared/toasts/toast",
      locals: {
        title: "Erro ao gerar PPTX",
        description: "Tente novamente em instantes.",
        kind: "error"
      }
    )
  end

  def stream_name
    "setlist_#{@setlist.id}"
  end
end

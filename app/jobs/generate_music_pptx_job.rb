class GenerateMusicPptxJob < ApplicationJob
  queue_as :default

  retry_on Slides::RenderError, attempts: 3, wait: :polynomially_longer do |job, error|
    job.send(:on_render_failure, error)
  end

  PPTX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.presentationml.presentation".freeze

  def perform(slide_deck_id)
    @slide_deck = SlideDeck.find(slide_deck_id)
    expected = Slides::Fingerprint.call(@slide_deck.slides_json, @slide_deck.slide_sequence, Slides::Theme::VERSION)

    return if @slide_deck.pptx_fingerprint == expected && @slide_deck.pptx.attached?

    binary = Slides::PptxRenderer.call(@slide_deck)
    @slide_deck.pptx.purge if @slide_deck.pptx.attached?
    @slide_deck.pptx.attach(
      io: StringIO.new(binary),
      filename: pptx_filename,
      content_type: PPTX_CONTENT_TYPE
    )
    @slide_deck.update_column(:pptx_fingerprint, expected)

    broadcast_ready
  end

  private

  def on_render_failure(_error)
    @slide_deck ||= SlideDeck.find_by(id: arguments.first)
    return unless @slide_deck

    @slide_deck.update_column(:pptx_fingerprint, nil) if @slide_deck.pptx_fingerprint.present?
    broadcast_error
  end

  def pptx_filename
    music = @slide_deck.slideable
    base = music.respond_to?(:slug) && music.slug.present? ? music.slug : "slides-#{@slide_deck.id}"
    "#{base}.pptx"
  end

  def broadcast_ready
    download_url = Rails.application.routes.url_helpers.rails_blob_path(@slide_deck.pptx, disposition: "attachment", only_path: true)

    Turbo::StreamsChannel.broadcast_append_to(
      stream_name,
      target: "toasts",
      partial: "shared/toasts/toast",
      locals: {
        title: "Pronto!",
        description: "O download do PPTX começou.",
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
    "slide_deck_#{@slide_deck.id}"
  end
end

require "test_helper"

class GenerateMusicPptxJobTest < ActiveJob::TestCase
  setup do
    @music = Repertoire::Music.create!(
      title: "Job Probe",
      author: repertoire_authors(:padre_jonas),
      content_raw: "[Estrofe 1]\nlinha um"
    )
    @slide_deck = @music.slide_deck
    # Ensure the deck has some content the renderer will exercise.
    @slide_deck.update!(
      slides_json: [
        { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "linha um" ] }
      ],
      slide_sequence: [ "verse_1" ]
    )
  end

  test "no-ops when the stored fingerprint matches and an attachment already exists" do
    expected = Slides::Fingerprint.call(@slide_deck.slides_json, @slide_deck.slide_sequence, Slides::Theme::VERSION)
    @slide_deck.update_column(:pptx_fingerprint, expected)
    @slide_deck.pptx.attach(io: StringIO.new("PREEXISTING"), filename: "preexisting.pptx", content_type: "application/vnd.openxmlformats-officedocument.presentationml.presentation")

    renderer_calls = 0
    with_renderer_stub(->(_deck) { renderer_calls += 1; "REGENERATED" }) do
      GenerateMusicPptxJob.perform_now(@slide_deck.id)
    end

    assert_equal 0, renderer_calls
    assert @slide_deck.reload.pptx.attached?
    assert_equal "PREEXISTING", @slide_deck.pptx.download
  end

  test "calls the renderer, attaches the binary, and updates the fingerprint when the deck is stale" do
    @slide_deck.update_column(:pptx_fingerprint, nil)

    with_renderer_stub(->(_deck) { "BINARY_PPTX" }) do
      GenerateMusicPptxJob.perform_now(@slide_deck.id)
    end

    @slide_deck.reload
    assert @slide_deck.pptx.attached?
    assert_equal "BINARY_PPTX", @slide_deck.pptx.download
    assert_equal "#{@music.slug}.pptx", @slide_deck.pptx.filename.to_s
    assert_equal Slides::Fingerprint.call(@slide_deck.slides_json, @slide_deck.slide_sequence, Slides::Theme::VERSION), @slide_deck.pptx_fingerprint
  end

  test "broadcasts the ready turbo stream replacing the spinner and appending a toast" do
    @slide_deck.update_column(:pptx_fingerprint, nil)

    bodies = capture_turbo_broadcasts do
      with_renderer_stub(->(_deck) { "BINARY_PPTX" }) do
        GenerateMusicPptxJob.perform_now(@slide_deck.id)
      end
    end

    assert bodies.any? { |body| body.include?("auto-download") }, "expected an auto-download turbo stream"
    assert bodies.any? { |body| body.include?("Pronto") }, "expected a 'Pronto' toast turbo stream"
  end

  test "after retries are exhausted clears the fingerprint and broadcasts an error toast" do
    @slide_deck.update_column(:pptx_fingerprint, "stale-but-set")

    bodies = capture_turbo_broadcasts do
      with_renderer_stub(->(_deck) { raise Slides::RenderError, "boom" }) do
        perform_enqueued_jobs do
          GenerateMusicPptxJob.perform_later(@slide_deck.id)
        end
      end
    end

    assert bodies.any? { |body| body.include?("Erro ao gerar PPTX") }, "expected an error toast broadcast"
    assert_nil @slide_deck.reload.pptx_fingerprint
  end

  private

  def capture_turbo_broadcasts
    bodies = []
    capture = ->(_stream, content:) { bodies << content.to_s }

    Turbo::StreamsChannel.singleton_class.alias_method(:__original_broadcast, :broadcast_stream_to)
    Turbo::StreamsChannel.define_singleton_method(:broadcast_stream_to) do |*streamables, content:|
      bodies << content.to_s
    end
    yield
    bodies
  ensure
    Turbo::StreamsChannel.singleton_class.alias_method(:broadcast_stream_to, :__original_broadcast)
    Turbo::StreamsChannel.singleton_class.send(:remove_method, :__original_broadcast)
  end

  def with_renderer_stub(callable)
    original = Slides::PptxRenderer.method(:call)
    Slides::PptxRenderer.singleton_class.alias_method(:__original_call, :call)
    Slides::PptxRenderer.define_singleton_method(:call) do |deck|
      callable.call(deck)
    end
    yield
  ensure
    Slides::PptxRenderer.singleton_class.alias_method(:call, :__original_call)
    Slides::PptxRenderer.singleton_class.send(:remove_method, :__original_call)
  end
end

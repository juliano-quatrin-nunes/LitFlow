require "test_helper"

class GenerateSetlistPptxJobTest < ActiveJob::TestCase
  setup do
    @user = users(:user)
    @music = Repertoire::Music.create!(
      title: "Setlist Job Probe",
      author: repertoire_authors(:padre_jonas),
      content_raw: "[E]linha"
    )
    @music.slide_deck.update!(
      slides_json: [ { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "linha" ] } ],
      slide_sequence: [ "verse_1" ]
    )
    @setlist = Setlist.create!(user: @user, name: "Setlist Job", setlist_type: "evento")
    @setlist.items.create!(item: @music)
  end

  test "no-ops when fingerprint matches and pptx is attached" do
    expected = Slides::Fingerprint.for_setlist(@setlist)
    @setlist.update_column(:pptx_fingerprint, expected)
    @setlist.pptx.attach(io: StringIO.new("PREEXISTING"), filename: "preexisting.pptx", content_type: "application/vnd.openxmlformats-officedocument.presentationml.presentation")

    calls = 0
    with_renderer_stub(->(_slides) { calls += 1; "REGENERATED" }) do
      GenerateSetlistPptxJob.perform_now(@setlist.id)
    end

    assert_equal 0, calls
    assert @setlist.reload.pptx.attached?
    assert_equal "PREEXISTING", @setlist.pptx.download
  end

  test "renders and attaches the binary, updates fingerprint, and uses parameterized filename" do
    @setlist.update_column(:pptx_fingerprint, nil)

    with_renderer_stub(->(_slides) { "BINARY_PPTX" }) do
      GenerateSetlistPptxJob.perform_now(@setlist.id)
    end

    @setlist.reload
    assert @setlist.pptx.attached?
    assert_equal "BINARY_PPTX", @setlist.pptx.download
    assert_equal "setlist-job.pptx", @setlist.pptx.filename.to_s
    assert_equal Slides::Fingerprint.for_setlist(@setlist), @setlist.pptx_fingerprint
  end

  test "passes the composed setlist slides (with blank bookends) to the renderer" do
    @setlist.update_column(:pptx_fingerprint, nil)

    received_slides = nil
    with_renderer_stub(->(slides) { received_slides = slides; "BINARY" }) do
      GenerateSetlistPptxJob.perform_now(@setlist.id)
    end

    assert_kind_of Array, received_slides
    assert_equal "blank", received_slides.first["type"]
    assert_equal "blank", received_slides.last["type"]
  end

  test "broadcasts a ready turbo stream with auto-download and a 'Pronto' toast" do
    @setlist.update_column(:pptx_fingerprint, nil)

    bodies = capture_turbo_broadcasts do
      with_renderer_stub(->(_slides) { "BINARY" }) do
        GenerateSetlistPptxJob.perform_now(@setlist.id)
      end
    end

    assert bodies.any? { |body| body.include?("auto-download") }, "expected auto-download stream"
    assert bodies.any? { |body| body.include?("Pronto") }, "expected ready toast"
  end

  test "exhausted retries clear the fingerprint and broadcast an error toast" do
    @setlist.update_column(:pptx_fingerprint, "stale-but-set")

    bodies = capture_turbo_broadcasts do
      with_renderer_stub(->(_slides) { raise Slides::RenderError, "boom" }) do
        perform_enqueued_jobs do
          GenerateSetlistPptxJob.perform_later(@setlist.id)
        end
      end
    end

    assert bodies.any? { |body| body.include?("Erro ao gerar PPTX") }
    assert_nil @setlist.reload.pptx_fingerprint
  end

  private

  def capture_turbo_broadcasts
    bodies = []
    Turbo::StreamsChannel.singleton_class.alias_method(:__original_broadcast, :broadcast_stream_to)
    Turbo::StreamsChannel.define_singleton_method(:broadcast_stream_to) do |*_streamables, content:|
      bodies << content.to_s
    end
    yield
    bodies
  ensure
    Turbo::StreamsChannel.singleton_class.alias_method(:broadcast_stream_to, :__original_broadcast)
    Turbo::StreamsChannel.singleton_class.send(:remove_method, :__original_broadcast)
  end

  def with_renderer_stub(callable)
    Slides::PptxRenderer.singleton_class.alias_method(:__original_render_slides, :render_slides)
    Slides::PptxRenderer.define_singleton_method(:render_slides) do |slides, **_kwargs|
      callable.call(slides)
    end
    yield
  ensure
    Slides::PptxRenderer.singleton_class.alias_method(:render_slides, :__original_render_slides)
    Slides::PptxRenderer.singleton_class.send(:remove_method, :__original_render_slides)
  end
end

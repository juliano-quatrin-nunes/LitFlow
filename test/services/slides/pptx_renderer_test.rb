require "test_helper"
require "open3"
require "ostruct"

class Slides::PptxRendererTest < ActiveSupport::TestCase
  setup do
    @slide_deck = slide_decks(:one)
    @slide_deck.update!(
      slides_json: [
        { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "Vem e eu mostrarei" ] },
        { "id" => "chorus_1", "type" => "chorus", "label" => "Refrão", "lines" => [ "AMÉM", "AMÉM" ] }
      ],
      slide_sequence: [ "verse_1", "chorus_1" ]
    )
  end

  test "builds a payload with the V1 theme constants and invokes the python script" do
    payload = run_renderer_and_capture_payload(@slide_deck)

    assert_equal Slides::Theme::V1.to_h, payload["theme"]
  end

  test "paginates each section into balanced pages and preserves its source type per physical slide" do
    @slide_deck.update!(
      slides_json: [
        { "id" => "chorus_1", "type" => "chorus", "label" => "Refrão", "lines" => Array.new(11) { |i| "linha #{i + 1}" } }
      ],
      slide_sequence: [ "chorus_1" ]
    )

    payload = run_renderer_and_capture_payload(@slide_deck)

    physical = payload["slides"]
    # 11 short lines = 11 rendered → balanced split into 6 + 5.
    assert_equal 2, physical.size
    assert_equal "chorus", physical[0]["type"]
    assert_equal "chorus", physical[1]["type"]
    assert_equal 6, physical[0]["lines"].size
    assert_equal 5, physical[1]["lines"].size
  end

  test "skips silently when a slide_sequence id has no matching section" do
    @slide_deck.update!(
      slides_json: [
        { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "Vem" ] }
      ],
      slide_sequence: [ "verse_1", "ghost_id", "verse_1" ]
    )

    payload = run_renderer_and_capture_payload(@slide_deck)

    physical = payload["slides"]
    assert_equal 2, physical.size
    assert_equal "verse", physical[0]["type"]
    assert_equal "verse", physical[1]["type"]
  end

  test "renders sections with empty lines as a single blank physical slide" do
    @slide_deck.update!(
      slides_json: [
        { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [] }
      ],
      slide_sequence: [ "verse_1" ]
    )

    payload = run_renderer_and_capture_payload(@slide_deck)

    physical = payload["slides"]
    assert_equal 1, physical.size
    assert_equal [], physical[0]["lines"]
    assert_equal "verse", physical[0]["type"]
  end

  test "render_slides forwards a custom slide list directly to the python script" do
    custom_slides = [
      { "type" => "blank", "lines" => [] },
      { "type" => "verse", "lines" => [ "alguma linha" ] },
      { "type" => "blank", "lines" => [] }
    ]
    captured_payload = nil
    capture3_stub = lambda do |*_args, **kwargs|
      captured_payload = JSON.parse(kwargs[:stdin_data])
      [ "BIN", "", success_status ]
    end

    with_open3_stub(capture3_stub) do
      binary = Slides::PptxRenderer.render_slides(custom_slides)
      assert_equal "BIN", binary
    end

    assert_equal custom_slides, captured_payload["slides"]
    assert_equal Slides::Theme::V1.to_h, captured_payload["theme"]
  end

  test "returns the stdout binary on success" do
    stub_open3([ "FAKE_PPTX_BINARY", "", success_status ]) do
      assert_equal "FAKE_PPTX_BINARY", Slides::PptxRenderer.call(@slide_deck)
    end
  end

  test "end-to-end: python renderer applies theme case=upper_case to every line of text" do
    payload_slides = [ { "type" => "verse", "lines" => [ "vem espírito", "vem alma minha" ] } ]
    theme = Slides::Theme::V1.to_h.merge("case" => "upper_case")

    binary = capture_payload_for_render(theme, payload_slides)

    # Unzip the PPTX (it's a zip archive) and look for the rendered run text.
    require "zip"
    rendered_text = Zip::InputStream.open(StringIO.new(binary)) do |io|
      collected = []
      while (entry = io.get_next_entry)
        collected << io.read.force_encoding("UTF-8") if entry.name.include?("slide1.xml")
      end
      collected.join
    end

    assert_match "VEM ESPÍRITO", rendered_text
    assert_match "VEM ALMA MINHA", rendered_text
    refute_match "vem espírito", rendered_text
  end

  test "end-to-end: python renderer leaves text untouched when theme case=normal" do
    payload_slides = [ { "type" => "verse", "lines" => [ "Vem Espírito" ] } ]
    theme = Slides::Theme::V1.to_h.merge("case" => "normal")

    binary = capture_payload_for_render(theme, payload_slides)

    require "zip"
    rendered_text = Zip::InputStream.open(StringIO.new(binary)) do |io|
      collected = []
      while (entry = io.get_next_entry)
        collected << io.read.force_encoding("UTF-8") if entry.name.include?("slide1.xml")
      end
      collected.join
    end

    assert_match "Vem Espírito", rendered_text
  end

  test "end-to-end: python renderer produces a valid PPTX from a blank-bookended setlist payload" do
    payload_slides = [
      { "type" => "blank", "lines" => [] },
      { "type" => "verse", "lines" => [ "uma linha" ] },
      { "type" => "blank", "lines" => [] }
    ]

    binary = Slides::PptxRenderer.render_slides(payload_slides)

    assert binary.bytesize > 0
    # PPTX is a zip archive — magic bytes are "PK"
    assert_equal "PK", binary[0, 2], "expected the renderer to output a zip (PPTX) file"
  end

  test "raises Slides::RenderError with stderr on non-zero exit" do
    error = assert_raises(Slides::RenderError) do
      stub_open3([ "", "boom: missing dep", failure_status ]) do
        Slides::PptxRenderer.call(@slide_deck)
      end
    end

    assert_match(/boom: missing dep/, error.message)
  end

  private

  def capture_payload_for_render(theme, slides)
    require "open3"
    payload = { "theme" => theme, "slides" => slides }.to_json
    stdout, _stderr, status = Open3.capture3(
      "python3",
      Rails.root.join("bin/render_pptx.py").to_s,
      stdin_data: payload,
      binmode: true
    )
    raise "render_pptx.py failed: #{_stderr}" unless status.success?
    stdout
  end

  def run_renderer_and_capture_payload(slide_deck)
    captured_payload = nil
    capture3_stub = lambda do |*_args, **kwargs|
      captured_payload = JSON.parse(kwargs[:stdin_data])
      [ "PPTX_BINARY", "", success_status ]
    end

    with_open3_stub(capture3_stub) do
      Slides::PptxRenderer.call(slide_deck)
    end

    captured_payload
  end

  def stub_open3(return_value)
    with_open3_stub(->(*_args, **_kwargs) { return_value }) { yield }
  end

  def with_open3_stub(callable)
    Open3.singleton_class.alias_method(:__original_capture3, :capture3)
    Open3.define_singleton_method(:capture3) do |*args, **kwargs|
      callable.call(*args, **kwargs)
    end
    yield
  ensure
    Open3.singleton_class.alias_method(:capture3, :__original_capture3)
    Open3.singleton_class.send(:remove_method, :__original_capture3)
  end

  def success_status
    OpenStruct.new(success?: true, exitstatus: 0)
  end

  def failure_status
    OpenStruct.new(success?: false, exitstatus: 1)
  end
end

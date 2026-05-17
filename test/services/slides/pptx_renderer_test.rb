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

  test "paginates each section and preserves its source type per physical slide" do
    @slide_deck.update!(
      slides_json: [
        { "id" => "chorus_1", "type" => "chorus", "label" => "Refrão", "lines" => Array.new(11) { |i| "linha #{i + 1}" } }
      ],
      slide_sequence: [ "chorus_1" ]
    )

    payload = run_renderer_and_capture_payload(@slide_deck)

    physical = payload["slides"]
    assert_equal 2, physical.size
    assert_equal "chorus", physical[0]["type"]
    assert_equal "chorus", physical[1]["type"]
    assert_equal 10, physical[0]["lines"].size
    assert_equal 1, physical[1]["lines"].size
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

  test "returns the stdout binary on success" do
    stub_open3([ "FAKE_PPTX_BINARY", "", success_status ]) do
      assert_equal "FAKE_PPTX_BINARY", Slides::PptxRenderer.call(@slide_deck)
    end
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

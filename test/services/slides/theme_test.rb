require "test_helper"

class Slides::ThemeTest < ActiveSupport::TestCase
  test "exposes VERSION constant" do
    assert_equal "v1.2", Slides::Theme::VERSION
  end

  test "V1 has the expected appearance constants" do
    assert_equal [ 10.0, 7.5 ], Slides::Theme::V1::ASPECT
    assert_equal "#000000", Slides::Theme::V1::BG_COLOR
    assert_equal "#FFFFFF", Slides::Theme::V1::TEXT_COLOR
    assert_equal "Calibri", Slides::Theme::V1::FONT_FAMILY
    assert_equal 42, Slides::Theme::V1::FONT_SIZE
    assert_equal :center, Slides::Theme::V1::H_ALIGN
    assert_equal :middle, Slides::Theme::V1::V_ALIGN
    assert_equal 0.05, Slides::Theme::V1::MARGINS
    assert_equal 28, Slides::Theme::V1::MAX_CHARS_PER_LINE
    assert_equal 10, Slides::Theme::V1::MAX_VISUAL_LINES
    assert_equal [ "chorus" ], Slides::Theme::V1::BOLD_SECTION_TYPES
  end

  test "V1 declares a CASE setting accepted by the renderer" do
    assert_includes %w[normal upper_case lower_case], Slides::Theme::V1::CASE
  end

  test "to_h forwards the case setting to the renderer payload" do
    assert_equal Slides::Theme::V1::CASE, Slides::Theme::V1.to_h["case"]
  end
end

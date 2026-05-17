require "test_helper"

class Slides::PhoneticStripTest < ActiveSupport::TestCase
  test "collapses runs of 3 identical adjacent letters to a single letter" do
    assert_equal "a", Slides::PhoneticStrip.call("aaa")
  end

  test "collapses runs of 4 identical adjacent letters to a single letter" do
    assert_equal "a", Slides::PhoneticStrip.call("aaaa")
  end

  test "leaves runs of 2 identical letters intact" do
    assert_equal "aa", Slides::PhoneticStrip.call("aa")
  end

  test "collapses multiple whitespace to a single space" do
    assert_equal "a b", Slides::PhoneticStrip.call("a    b")
  end

  test "trims leading and trailing whitespace" do
    assert_equal "a b", Slides::PhoneticStrip.call("  a  b  ")
  end

  test "is case-insensitive when collapsing repeated letters" do
    assert_equal "A", Slides::PhoneticStrip.call("AAAA")
  end

  test "collapses unicode letters and preserves them" do
    assert_equal "é", Slides::PhoneticStrip.call("ééé")
  end

  test "applies all three rules together on a realistic phrase" do
    assert_equal "a a - me m", Slides::PhoneticStrip.call("  aaa  aaa  -  meee  m  ")
  end
end

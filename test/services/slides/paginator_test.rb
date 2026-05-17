require "test_helper"

class Slides::PaginatorTest < ActiveSupport::TestCase
  test "four short lines fit in a single page" do
    lines = [ "linha 1", "linha 2", "linha 3", "linha 4" ]

    assert_equal [ lines ], Slides::Paginator.call(lines)
  end

  test "eleven short lines split ten on the first page and one on the second" do
    lines = Array.new(11) { |i| "linha #{i + 1}" }

    pages = Slides::Paginator.call(lines)

    assert_equal 2, pages.size
    assert_equal 10, pages[0].size
    assert_equal 1, pages[1].size
    assert_equal lines, pages.flatten
  end

  test "a line longer than the char threshold counts as two units" do
    long = "x" * 40
    short = "curta"
    lines = [ long, long, long, long, long, short ]

    pages = Slides::Paginator.call(lines)

    assert_equal 2, pages.size
    assert_equal [ long, long, long, long, long ], pages[0]
    assert_equal [ short ], pages[1]
  end

  test "empty input returns one blank physical page" do
    assert_equal [ [] ], Slides::Paginator.call([])
  end
end

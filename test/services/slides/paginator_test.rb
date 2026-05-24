require "test_helper"

class Slides::PaginatorTest < ActiveSupport::TestCase
  test "four short lines fit in a single page" do
    lines = [ "linha 1", "linha 2", "linha 3", "linha 4" ]

    assert_equal [ lines ], Slides::Paginator.call(lines)
  end

  test "a single overlong word splits into ceil(length / max_chars) visual lines" do
    # No word boundaries → must split mid-word, ceil(65/30) = 3 visual lines.
    long_word = "x" * 65
    # 3 such "lines" = 3 × 3 = 9 visual ≤ 10 → one page.
    assert_equal 1, Slides::Paginator.call([ long_word, long_word, long_word ]).size
    # 4 such lines = 12 visual → splits balanced (6 + 6).
    assert_equal 2, Slides::Paginator.call([ long_word, long_word, long_word, long_word ]).size
  end

  test "word-wrap uses last full-word boundary that strictly fits under max_chars" do
    # "CORDEIRO DE DEUS QUE TIRAIS O PECADO DO MUNDO, TENDE PIEDADE" (60 chars):
    #   visual 1: "CORDEIRO DE DEUS QUE TIRAIS O" (29 chars — adding "PECADO" would exceed 30)
    #   visual 2: "PECADO DO MUNDO, TENDE" (22 chars — adding "PIEDADE" would land at exactly 30, which is not < 30)
    #   visual 3: "PIEDADE" (7 chars)
    # → 3 rendered visual lines for this single source line.
    line = "CORDEIRO DE DEUS QUE TIRAIS O PECADO DO MUNDO, TENDE PIEDADE"
    # 3 such source lines = 9 visual → one page.
    assert_equal 1, Slides::Paginator.call([ line, line, line ]).size
    # 4 such lines = 12 visual → splits.
    assert_equal 2, Slides::Paginator.call([ line, line, line, line ]).size
  end

  test "the user's exact cordeiro section splits 2 + 3 source lines naturally" do
    # Visual line counts under greedy word-wrap with strict-fit:
    #   line 1 (60 chars, comma): wraps to 3 visual lines
    #   line 2 (59 chars):        2 visual
    #   line 3 (45 chars):        2 visual
    #   line 4 (32 chars):        2 visual
    #   line 5 (34 chars):        2 visual
    # Total = 11 → splits at target ceil(11/2) = 6:
    #   page 1: lines 1+2 (3+2 = 5 visual)
    #   page 2: lines 3+4+5 (2+2+2 = 6 visual)
    lines = [
      "CORDEIRO DE DEUS QUE TIRAIS O PECADO DO MUNDO, TENDE PIEDADE",
      "CORDEIRO DE DEUS QUE TIRAIS O PECADO DO MUNDO TENDE PIEDADE",
      "CORDEIRO DE DEUS QUE TIRAIS O PECADO DO MUNDO",
      "DAI-NOS A PA---AZ, DAI-NOS A PAZ",
      "DAI-NOS A VOSSA PAZ, DAI-NOS A PAZ"
    ]

    pages = Slides::Paginator.call(lines)

    assert_equal 2, pages.size
    assert_equal lines[0, 2], pages[0]
    assert_equal lines[2, 3], pages[1]
  end

  test "balanced split: 12 short lines distributes 6 + 6 across two pages" do
    lines = Array.new(12) { |i| "linha #{i + 1}" }

    pages = Slides::Paginator.call(lines)

    assert_equal 2, pages.size
    assert_equal 6, pages[0].size
    assert_equal 6, pages[1].size
    assert_equal lines, pages.flatten
  end

  test "balanced split: 11 short lines distributes 6 + 5 across two pages" do
    lines = Array.new(11) { |i| "linha #{i + 1}" }

    pages = Slides::Paginator.call(lines)

    assert_equal 2, pages.size
    assert_equal 6, pages[0].size
    assert_equal 5, pages[1].size
    assert_equal lines, pages.flatten
  end

  test "exactly max_visual short lines fit in a single page (no forced split when total == cap)" do
    lines = Array.new(10) { |i| "linha #{i + 1}" }

    assert_equal 1, Slides::Paginator.call(lines).size
  end

  test "balanced split honors per-line wrap cost (mid-source-line wraps)" do
    # 40-char single word → ceil(40/30) = 2 visual lines.
    long = "x" * 40
    short = "curta"
    # Total cost: 5*2 + 1 = 11 → 2 pages, target = ceil(11/2) = 6.
    # Greedy: page1 = 3 longs (cost 6), page2 = 2 longs + short (cost 5).
    lines = [ long, long, long, long, long, short ]

    pages = Slides::Paginator.call(lines)

    assert_equal 2, pages.size
    assert_equal [ long, long, long ], pages[0]
    assert_equal [ long, long, short ], pages[1]
  end

  test "empty input returns one blank physical page" do
    assert_equal [ [] ], Slides::Paginator.call([])
  end

  test "max_chars and max_visual default to the Theme constants" do
    line = "x" * Slides::Theme::V1::MAX_CHARS_PER_LINE
    # max_visual single-word lines of exactly max_chars each = max_visual visual → single page.
    pages = Slides::Paginator.call(Array.new(Slides::Theme::V1::MAX_VISUAL_LINES) { line })
    assert_equal 1, pages.size
  end
end

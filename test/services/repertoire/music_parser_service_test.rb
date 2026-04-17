require "test_helper"

class Repertoire::MusicParserServiceTest < ActiveSupport::TestCase
  test "should parse standard chords-over-lyrics format" do
    input = <<~TEXT
      E                  C#m
      Vem e eu mostrarei que o meu caminho
    TEXT

    result = Repertoire::MusicParserService.call(input)

    assert_equal "[E]Vem e eu mostrarei [C#m]que o meu caminho", result[:raw]

    expected_json = [
      {
        type: "line",
        parts: [
          { chord: "E", lyric: "Vem e eu mostrarei " },
          { chord: "C#m", lyric: "que o meu caminho" }
        ]
      }
    ]
    assert_equal expected_json, result[:json]
  end

  test "should handle multiple chords on one line" do
    input = <<~TEXT
      A       D       E       A
      Lalalal lalalal lalalal lala
    TEXT

    result = Repertoire::MusicParserService.call(input)
    assert_equal "[A]Lalalal [D]lalalal [E]lalalal [A]lala", result[:raw]
  end

  test "should handle lines with only lyrics" do
    input = "Just a simple lyric line"
    result = Repertoire::MusicParserService.call(input)

    assert_equal "Just a simple lyric line", result[:raw]
    assert_equal [ { type: "line", parts: [ { lyric: "Just a simple lyric line" } ] } ], result[:json]
  end

  test "should handle lines with only chords" do
    input = "E  C#m  A  B"
    result = Repertoire::MusicParserService.call(input)

    assert_equal "[E]  [C#m]  [A]  [B]", result[:raw]
    expected_parts = [
      { chord: "E", lyric: "  " },
      { chord: "C#m", lyric: "  " },
      { chord: "A", lyric: "  " },
      { chord: "B", lyric: "" }
    ]
    assert_equal expected_parts, result[:json].first[:parts]
  end

  test "should handle mixed content with multiple stanzas" do
    input = <<~TEXT
      E                  C#m
      Vem e eu mostrarei que o meu caminho

      A                  B
      Te leva ao Pai
    TEXT

    result = Repertoire::MusicParserService.call(input)

    lines = result[:raw].split("\n")
    assert_equal "[E]Vem e eu mostrarei [C#m]que o meu caminho", lines[0]
    assert_equal "", lines[1]
    assert_equal "[A]Te leva ao Pai[B]", lines[2]
  end

  test "should handle already-parsed ChordPro format" do
    input = "[E]Already [C#m]parsed"
    result = Repertoire::MusicParserService.call(input)

    assert_equal "[E]Already [C#m]parsed", result[:raw]
    assert_equal "E", result[:json].first[:parts][0][:chord]
    assert_equal "Already ", result[:json].first[:parts][0][:lyric]
  end

  test "should handle chords at the very end of a line" do
    input = <<~TEXT
                      E
      At the end
    TEXT
    result = Repertoire::MusicParserService.call(input)
    assert_equal "At the end[E]", result[:raw]
  end
end

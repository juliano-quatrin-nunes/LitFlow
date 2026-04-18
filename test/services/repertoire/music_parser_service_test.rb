require "test_helper"

class Repertoire::MusicParserServiceTest < ActiveSupport::TestCase
  test "should parse standard chords-over-lyrics format into sections" do
    input = <<~TEXT
      E                  C#m
      Vem e eu mostrarei que o meu caminho
    TEXT

    result = Repertoire::MusicParserService.call(input)

    expected_raw = "E                  C#m\nVem e eu mostrarei que o meu caminho"
    assert_equal expected_raw, result[:raw]

    expected_json = [
      {
        type: "verse",
        lines: [
          {
            parts: [
              { chord: "E", lyric: "Vem e eu mostrarei " },
              { chord: "C#m", lyric: "que o meu caminho" }
            ]
          }
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
    expected_raw = "A       D       E       A\nLalalal lalalal lalalal lala"
    assert_equal expected_raw, result[:raw]
  end

  test "should handle lines with only lyrics as verse" do
    input = "Just a simple lyric line"
    result = Repertoire::MusicParserService.call(input)

    assert_equal "Just a simple lyric line", result[:raw]
    assert_equal "verse", result[:json].first[:type]
    assert_equal "Just a simple lyric line", result[:json].first[:lines].first[:parts].first[:lyric]
  end

  test "should handle lines with only chords as intro" do
    input = "E  C#m  A  B"
    result = Repertoire::MusicParserService.call(input)

    assert_equal "E C#m A B", result[:raw]
    assert_equal "intro", result[:json].first[:type]
  end

  test "should handle explicit labels with repeated sections" do
    input = <<~TEXT
      [Primeira Parte]

       D                      Bm
      Cristo, quero ser instrumento
                       G  E7            A  A7
      De tua paz e do teu    infinito amor
      D                     Bm
      Onde houver ódio e rancor
                        G     E7                 A  D7
      Que eu leve a concórdia,   que eu leve o amor

      [Refrão]

      G                   A                    F#m
      Onde há ofensa que dói, que eu leve o perdão
                        G                       A  A7     D  G  A7
      Onde houver a discórdia, que eu leve a união e tua paz
    TEXT

    result = Repertoire::MusicParserService.call(input)
    # 6 labels + 6 content sections = 12 total sections
    assert_equal 4, result[:json].length

    # Check types
    assert_equal "label", result[:json][0][:type]
    assert_equal "verse", result[:json][1][:type]
    assert_equal "label", result[:json][2][:type]
    assert_equal "chorus", result[:json][3][:type]
  end

  test "should split into multiple verses and intros based on implicit content" do
    input = <<~TEXT
      G                 Em              Am                D
         Vem e eu mostrarei que o meu caminho te leva ao pai
             G             Em             Am             D
         Guiarei os passos teus e junto a Ti hei de seguir
                  G        B          C     D
         Sim, eu irei e saberei como chegar ao fim
                 G            B              C     D      G
         De onde vim pra onde vou, por onde irás, irei, também

      ( G  Em  Am  D )

          G            Em                Am           D
         Vem e eu te direi o que ainda estás a procurar
              G             Em           Am           D
         A verdade é como o sol e invadirá o teu coração
                 G            B           C      D
         Sim eu irei e aprenderei minha razão de ser
                     G              B          C        D     G
         Eu creio em Ti que crês em mim, e Tua luz, verei a luz
    TEXT

    result = Repertoire::MusicParserService.call(input)

    # 2 verses and 1 intro in between = 3 sections
    assert_equal 3, result[:json].length
    assert_equal "verse", result[:json][0][:type]
    assert_equal "intro", result[:json][1][:type]
    assert_equal "verse", result[:json][2][:type]
  end

  test "should handle intro chords in parentheses by stripping them" do
    input = "( G  Em  Am  D )"
    result = Repertoire::MusicParserService.call(input)

    assert_equal "intro", result[:json].first[:type]
    assert_equal "G Em Am D", result[:raw]
  end

  test "should handle already-parsed ChordPro format" do
    input = "[E]Already [C#m]parsed"
    result = Repertoire::MusicParserService.call(input)

    expected_raw = "E       C#m\nAlready parsed"
    assert_equal expected_raw, result[:raw]
    assert_equal "E", result[:json].first[:lines].first[:parts][0][:chord]
  end
end

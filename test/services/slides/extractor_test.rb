require "test_helper"

class Slides::ExtractorTest < ActiveSupport::TestCase
  test "extracts sections with ids, default labels, and phonetic-stripped lyric lines" do
    cifra = <<~TEXT
      [Estrofe 1]

      E                  C#m
      Vem e eu mostrarei que o meu caminho

      [Refrão]

      G                   A
      Onde há ofensa que dói

      [Estrofe 2]

      D                     Bm
      Onde houver ódio e rancor
    TEXT

    content_json = Repertoire::MusicParserService.call(cifra)[:json]
    slides = Slides::Extractor.call(content_json)

    typed = slides.reject { |s| s[:type] == "label" }

    assert_equal [ "verse_1", "chorus_1", "verse_2" ], typed.map { |s| s[:id] }
    assert_equal [ "verse", "chorus", "verse" ], typed.map { |s| s[:type] }
    assert_equal [ "Estrofe 1", "Refrão", "Estrofe 2" ], typed.map { |s| s[:label] }

    assert_equal [ "Vem e eu mostrarei que o meu caminho" ], typed[0][:lines]
    assert_equal [ "Onde há ofensa que dói" ], typed[1][:lines]
    assert_equal [ "Onde houver ódio e rancor" ], typed[2][:lines]
  end

  test "sections with no lyric content remain in slides_json with empty lines" do
    cifra = <<~TEXT
      E  C#m  A  B

      G                   A
      Vem e eu mostrarei
    TEXT

    content_json = Repertoire::MusicParserService.call(cifra)[:json]
    slides = Slides::Extractor.call(content_json)

    assert_equal "intro_1", slides[0][:id]
    assert_equal "intro", slides[0][:type]
    assert_equal "Intro", slides[0][:label]
    assert_equal [], slides[0][:lines]

    assert_equal "verse_1", slides[1][:id]
    assert_equal [ "Vem e eu mostrarei" ], slides[1][:lines]
  end

  test "ids are deterministic across repeated runs over the same input" do
    cifra = <<~TEXT
      [Refrão]

      G                   A
      Refrão linha um

      [Estrofe 1]

      D                     Bm
      Estrofe linha um

      [Refrão]

      G                   A
      Refrão linha dois

      [Estrofe 2]

      D                     Bm
      Estrofe linha dois
    TEXT

    content_json = Repertoire::MusicParserService.call(cifra)[:json]

    first_run = Slides::Extractor.call(content_json).map { |s| s[:id] }
    second_run = Slides::Extractor.call(content_json).map { |s| s[:id] }

    assert_equal first_run, second_run

    typed_ids = Slides::Extractor.call(content_json).reject { |s| s[:type] == "label" }.map { |s| s[:id] }
    assert_equal [ "chorus_1", "verse_1", "chorus_2", "verse_2" ], typed_ids
  end

  test "default_sequence excludes empty-lyric sections" do
    cifra = <<~TEXT
      E  C#m  A  B

      G                   A
      Vem e eu mostrarei

      [Refrão]

      D                     Bm
      Refrão linha
    TEXT

    content_json = Repertoire::MusicParserService.call(cifra)[:json]
    slides = Slides::Extractor.call(content_json)

    sequence = Slides::Extractor.default_sequence(slides)

    assert_not_includes sequence, "intro_1"
    assert_not_includes sequence, "label_1"
    assert_equal [ "verse_1", "chorus_1" ], sequence
  end

  test "phonetic strip is applied to the joined lyric of each line" do
    cifra = <<~TEXT
      G                   A
      aaa   aaa   meee
    TEXT

    content_json = Repertoire::MusicParserService.call(cifra)[:json]
    slides = Slides::Extractor.call(content_json)

    assert_equal [ "a a me" ], slides[0][:lines]
  end
end

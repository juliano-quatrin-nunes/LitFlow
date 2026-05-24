require "test_helper"

class Slides::SetlistComposerTest < ActiveSupport::TestCase
  setup do
    @user = users(:user)
    @setlist = Setlist.create!(user: @user, name: "Composição", setlist_type: "evento")
  end

  test "3-item setlist emits 4 blank slides with item slides interleaved in position order" do
    musics = 3.times.map do |i|
      Repertoire::Music.create!(
        title: "Item #{i + 1}",
        author: repertoire_authors(:padre_jonas),
        content_raw: "[E]linha #{i + 1}"
      ).tap do |m|
        m.slide_deck.update!(
          slides_json: [ { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "linha #{i + 1}" ] } ],
          slide_sequence: [ "verse_1" ]
        )
      end
    end
    musics.each { |m| @setlist.items.create!(item: m) }

    slides = Slides::SetlistComposer.call(@setlist)
    blanks = slides.select { |s| s["type"] == "blank" }
    non_blanks = slides.reject { |s| s["type"] == "blank" }

    assert_equal 4, blanks.size, "expected blanks = items + 1"
    assert_equal 3, non_blanks.size, "expected one non-blank slide per item"
    assert_equal "blank", slides.first["type"], "deck must start with a blank"
    assert_equal "blank", slides.last["type"], "deck must end with a blank"
    assert_equal [ "linha 1" ], non_blanks[0]["lines"]
    assert_equal [ "linha 2" ], non_blanks[1]["lines"]
    assert_equal [ "linha 3" ], non_blanks[2]["lines"]
  end

  test "1-item setlist emits exactly 2 blank slides bracketing the single item" do
    music = Repertoire::Music.create!(
      title: "Solo",
      author: repertoire_authors(:padre_jonas),
      content_raw: "[E]única"
    )
    music.slide_deck.update!(
      slides_json: [ { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "única" ] } ],
      slide_sequence: [ "verse_1" ]
    )
    @setlist.items.create!(item: music)

    slides = Slides::SetlistComposer.call(@setlist)

    assert_equal 2, slides.count { |s| s["type"] == "blank" }
    assert_equal "blank", slides.first["type"]
    assert_equal "blank", slides.last["type"]
    assert_equal 3, slides.size
  end

  test "orphaned sequence ids inside an item override are silently skipped" do
    music = Repertoire::Music.create!(
      title: "Órfã",
      author: repertoire_authors(:padre_jonas),
      content_raw: "[E]linha"
    )
    music.slide_deck.update!(
      slides_json: [ { "id" => "verse_1", "type" => "verse", "label" => "x", "lines" => [ "a" ] } ],
      slide_sequence: [ "verse_1" ]
    )
    @setlist.items.create!(
      item: music,
      slide_sequence_override: [ "verse_1", "ghost", "verse_1" ]
    )

    slides = Slides::SetlistComposer.call(@setlist)
    non_blanks = slides.reject { |s| s["type"] == "blank" }

    assert_equal 2, non_blanks.size, "expected the two valid 'verse_1' entries; the orphan id should be skipped"
  end

  test "respects effective_slides_json and effective_slide_sequence overrides" do
    music = Repertoire::Music.create!(
      title: "Custom",
      author: repertoire_authors(:padre_jonas),
      content_raw: "[E]original"
    )
    music.slide_deck.update!(
      slides_json: [ { "id" => "verse_1", "type" => "verse", "label" => "x", "lines" => [ "original" ] } ],
      slide_sequence: [ "verse_1" ]
    )
    @setlist.items.create!(
      item: music,
      slides_json_override: [ { "id" => "verse_1", "type" => "chorus", "label" => "x", "lines" => [ "custom!" ] } ],
      slide_sequence_override: [ "verse_1" ]
    )

    slides = Slides::SetlistComposer.call(@setlist)
    non_blanks = slides.reject { |s| s["type"] == "blank" }

    assert_equal 1, non_blanks.size
    assert_equal "chorus", non_blanks.first["type"]
    assert_equal [ "custom!" ], non_blanks.first["lines"]
  end

  test "empty setlist produces a single blank slide (deck-start blank, no items to follow)" do
    slides = Slides::SetlistComposer.call(@setlist)
    assert_equal 1, slides.size
    assert_equal "blank", slides.first["type"]
  end
end

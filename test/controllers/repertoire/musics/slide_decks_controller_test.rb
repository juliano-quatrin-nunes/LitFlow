require "test_helper"

class Repertoire::Musics::SlideDecksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:user)
    @music = repertoire_musics(:one)
  end

  test "create renders the editor for the current content_raw without persisting" do
    deck = @music.slide_deck
    original_json = deck.slides_json.dup
    original_generated_from = deck.slides_generated_from

    post repertoire_music_slide_deck_path(@music.author, @music),
         params: { repertoire_music: { content_raw: "E\nLetra somente para preview" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "Letra somente para preview", response.body

    deck.reload
    assert_equal original_json, deck.slides_json
    assert_equal original_generated_from, deck.slides_generated_from
  end

  test "update persists slide edits and leaves slides_generated_from untouched" do
    deck = @music.slide_deck
    original_generated_from = deck.slides_generated_from
    edited_sections = [
      { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "Linha editada manualmente" ] }
    ]

    patch repertoire_music_slide_deck_path(@music.author, @music),
          params: {
            slide_deck: {
              slides_json: edited_sections.to_json,
              slide_sequence: [ "verse_1" ].to_json
            }
          },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    deck.reload
    assert_equal edited_sections, deck.slides_json
    assert_equal [ "verse_1" ], deck.slide_sequence
    assert_equal original_generated_from, deck.slides_generated_from
  end

  test "regenerate overwrites slides_json, slide_sequence, and slides_generated_from" do
    deck = @music.slide_deck

    new_cifra = "E\nNova letra para regenerar"
    @music.update_column(:content_raw, new_cifra)
    @music.update_column(:content_json, nil)

    post repertoire_music_regenerate_slide_deck_path(@music.author, @music),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    deck.reload
    assert_includes deck.slides_json.first["lines"].join(" "), "Nova letra"
    assert_equal Digest::SHA1.hexdigest(new_cifra), deck.slides_generated_from
    assert_equal deck.slides_json.map { |s| s["id"] }, deck.slide_sequence
  end
end

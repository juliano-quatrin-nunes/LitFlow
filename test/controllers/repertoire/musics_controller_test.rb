require "test_helper"

class Repertoire::MusicsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get repertoire_musics_url
    assert_response :success
  end

  test "should show music" do
    music = repertoire_musics(:one)
    get repertoire_music_by_author_url(music.author, music)
    assert_response :success
    assert_select ".text-accent-foreground", text: "E"
  end

  test "should show transposed music" do
    music = repertoire_musics(:one)
    get repertoire_music_by_author_url(music.author, music, key: "G")
    assert_response :success
    assert_select ".text-accent-foreground", text: "G"
    assert_select "span", text: "G" # The current key in KeyMutator
  end

  test "should filter music by season" do
    music = repertoire_musics(:one)
    season = repertoire_liturgical_seasons(:one)
    music.liturgical_seasons << season

    get repertoire_musics_url(season: season.slug)
    assert_response :success
    assert_select "h2", text: music.title

    other_music = repertoire_musics(:two)
    assert_select "h2", { text: other_music.title, count: 0 }
  end

  test "should include general (geral) season music when filtering by specific season" do
    music = repertoire_musics(:one)
    season = repertoire_liturgical_seasons(:one)
    music.liturgical_seasons << season

    general_music = repertoire_musics(:two)
    general_season = Repertoire::LiturgicalSeason.find_or_create_by!(name: "Geral", slug: "geral")
    general_music.liturgical_seasons << general_season

    get repertoire_musics_url(season: season.slug)
    assert_response :success
    assert_select "h2", text: music.title
    assert_select "h2", text: general_music.title
  end

  test "should filter music by mass part" do
    music = repertoire_musics(:one)
    part = repertoire_mass_parts(:one)
    music.mass_parts << part

    get repertoire_musics_url(part: part.slug)
    assert_response :success
    assert_select "h2", text: music.title

    other_music = repertoire_musics(:two)
    assert_select "h2", { text: other_music.title, count: 0 }
  end

  test "should combine filters" do
    music = repertoire_musics(:one)
    season = repertoire_liturgical_seasons(:one)
    part = repertoire_mass_parts(:one)
    music.liturgical_seasons << season
    music.mass_parts << part

    other_music = repertoire_musics(:two)
    other_music.liturgical_seasons << season

    get repertoire_musics_url(season: season.slug, part: part.slug)
    assert_response :success
    assert_select "h2", text: music.title
    assert_select "h2", { text: other_music.title, count: 0 }
  end

  test "should search music by title" do
    music = repertoire_musics(:one)
    get repertoire_musics_url(q: music.title)
    assert_response :success
    assert_select "h2", text: music.title
    
    other_music = repertoire_musics(:two)
    assert_select "h2", { text: other_music.title, count: 0 }
  end

  test "should search music by author name" do
    music = repertoire_musics(:one)
    get repertoire_musics_url(q: music.author.name)
    assert_response :success
    assert_select "h2", text: music.title
  end

  test "should search music by lyrics" do
    music = repertoire_musics(:one) # Content: [E]Vem [A]Espírito
    get repertoire_musics_url(q: "Espírito")
    assert_response :success
    assert_select "h2", text: music.title
  end

  test "library scope mine returns only musics saved by the current user" do
    user = users(:user)
    sign_in_as user
    mine = repertoire_musics(:one)
    other = repertoire_musics(:two)
    SavedMusic.create!(user: user, music: mine)

    get repertoire_musics_url(library: "mine")

    assert_response :success
    assert_select "h2", text: mine.title
    assert_select "h2", { text: other.title, count: 0 }
  end

  test "library scope all returns every music (default behavior)" do
    user = users(:user)
    sign_in_as user
    mine = repertoire_musics(:one)
    other = repertoire_musics(:two)
    SavedMusic.create!(user: user, music: mine)

    get repertoire_musics_url(library: "all")

    assert_response :success
    assert_select "h2", text: mine.title
    assert_select "h2", text: other.title
  end

  test "new page surfaces a slide section explaining slides will be generated on save" do
    sign_in_as users(:user)

    get new_repertoire_music_url

    assert_response :success
    assert_select "[data-role=slide-section-placeholder]"
    assert_match "slides", response.body
  end

  test "create redirects to edit so the user can refine slides immediately" do
    sign_in_as users(:user)
    author = repertoire_authors(:padre_jonas)

    post repertoire_musics_url, params: {
      repertoire_music: {
        title: "Música Nova com Slides",
        author_id: author.id,
        original_key: "E",
        content_raw: "[E]linha"
      }
    }

    music = Repertoire::Music.find_by!(title: "Música Nova com Slides")
    assert_redirected_to repertoire_music_by_author_edit_path(music.author, music)
  end

  test "edit page renders the slide editor inline when slide_deck has slides" do
    sign_in_as users(:user)
    music = repertoire_musics(:one)

    get repertoire_music_by_author_edit_url(music.author, music)

    assert_response :success
    assert_select "turbo-frame[id=slide_deck_editor]" do
      assert_select "[data-controller~=slide-section-editor]"
    end
  end

  test "edit page shows generate button when slide_deck has no slides yet" do
    sign_in_as users(:user)
    music = repertoire_musics(:one)
    music.slide_deck.update!(slides_json: [], slide_sequence: [])

    get repertoire_music_by_author_edit_url(music.author, music)

    assert_response :success
    assert_match repertoire_music_slide_deck_path(music.author, music), response.body
    assert_select "turbo-frame[id=slide_deck_editor] [data-controller~=slide-section-editor]", false
  end

  test "edit page shows cifra-changed hint when content_raw hash differs from slides_generated_from" do
    sign_in_as users(:user)
    music = repertoire_musics(:one)
    music.slide_deck.update!(slides_generated_from: "some-old-hash-that-does-not-match")

    get repertoire_music_by_author_edit_url(music.author, music)

    assert_response :success
    assert_select "[data-role=cifra-changed-banner]"
  end

  test "edit page hides cifra-changed hint when hashes match" do
    sign_in_as users(:user)
    music = repertoire_musics(:one)
    music.slide_deck.update!(slides_generated_from: Digest::SHA1.hexdigest(music.content_raw))

    get repertoire_music_by_author_edit_url(music.author, music)

    assert_response :success
    assert_select "[data-role=cifra-changed-banner]", false
  end

  test "Music update with changed content_raw does not overwrite slides_json or slide_sequence" do
    user = users(:user)
    sign_in_as user
    music = repertoire_musics(:one)
    deck = music.slide_deck
    original_slides_json = deck.slides_json.deep_dup
    original_sequence = deck.slide_sequence.deep_dup
    original_generated_from = deck.slides_generated_from

    patch repertoire_music_by_author_update_url(music.author, music),
          params: { repertoire_music: { content_raw: "G\nUma cifra totalmente diferente" } }

    deck.reload
    assert_equal original_slides_json, deck.slides_json
    assert_equal original_sequence, deck.slide_sequence
    assert_equal original_generated_from, deck.slides_generated_from
  end

  test "Music update persists slide edits alongside content_raw atomically" do
    user = users(:user)
    sign_in_as user
    music = repertoire_musics(:one)
    edited_sections = [
      { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "Letra editada na mesma submissão" ] }
    ]

    patch repertoire_music_by_author_update_url(music.author, music),
          params: {
            repertoire_music: {
              content_raw: "[E]Letra atualizada",
              slide_deck_attributes: {
                id: music.slide_deck.id,
                slides_json: edited_sections.to_json,
                slide_sequence: [ "verse_1" ].to_json
              }
            }
          }

    music.reload
    assert_includes music.content_raw, "Letra atualizada"
    assert_equal edited_sections, music.slide_deck.slides_json
    assert_equal [ "verse_1" ], music.slide_deck.slide_sequence
  end

  test "should show liturgical context on music page" do
    music = repertoire_musics(:one)
    season = repertoire_liturgical_seasons(:one)
    part = repertoire_mass_parts(:one)

    music.liturgical_seasons << season
    music.mass_parts << part

    get repertoire_music_by_author_url(music.author, music)
    assert_response :success

    assert_select "a[href=?]", repertoire_musics_path(season: season.slug), text: /#{season.name}/
    assert_select "a[href=?]", repertoire_musics_path(part: part.slug), text: /#{part.name}/
  end
end

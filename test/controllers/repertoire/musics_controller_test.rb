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

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
    assert_select "div.text-blue-600", text: "E"
  end

  test "should show transposed music" do
    music = repertoire_musics(:one)
    get repertoire_music_by_author_url(music.author, music, key: "G")
    assert_response :success
    assert_select "div.text-blue-600", text: "G"
    assert_select "span", text: "G" # The badge
  end
end

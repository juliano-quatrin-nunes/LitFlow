require "test_helper"

class Repertoire::MusicsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get repertoire_musics_url
    assert_response :success
  end

  test "should show music" do
    music = Repertoire::Music.create!(title: "Test Music", content_raw: "E\nTest")
    get repertoire_music_url(music)
    assert_response :success
  end
end

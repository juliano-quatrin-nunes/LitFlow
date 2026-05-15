require "test_helper"

class SavedMusicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user)
    @music = repertoire_musics(:one)
    sign_in_as @user
  end

  test "should get index" do
    get saved_musics_url
    assert_response :success
  end

  test "should create saved_music" do
    assert_difference("SavedMusic.count") do
      post saved_musics_url, params: { music_id: @music.id, saved_music: { preferred_key: "G", remarks: "Capo 2" } }
    end
    assert_redirected_to repertoire_music_by_author_show_url(@music.author, @music, key: "G")

    saved = SavedMusic.last
    assert_equal "G", saved.preferred_key
    assert_equal "Capo 2", saved.remarks
  end

  test "should update saved_music" do
    saved = SavedMusic.create!(user: @user, music: @music, preferred_key: "C")
    patch saved_music_url(saved), params: { saved_music: { preferred_key: "D", remarks: "Updated" } }
    assert_redirected_to repertoire_music_by_author_show_url(@music.author, @music, key: "D")

    saved.reload
    assert_equal "D", saved.preferred_key
    assert_equal "Updated", saved.remarks
  end

  test "should destroy saved_music" do
    saved = SavedMusic.create!(user: @user, music: @music)
    assert_difference("SavedMusic.count", -1) do
      delete saved_music_url(saved)
    end
    assert_redirected_to repertoire_music_by_author_show_url(@music.author, @music)
  end

  test "should redirect to login when guest" do
    sign_out
    get saved_musics_url
    assert_redirected_to new_session_url
  end
end
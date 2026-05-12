require "test_helper"

class SavedMusicTest < ActiveSupport::TestCase
  test "should be valid with user and music" do
    saved = SavedMusic.new(user: users(:user), music: repertoire_musics(:one))
    assert saved.valid?
  end

  test "should validate uniqueness of music per user" do
    user = users(:user)
    music = repertoire_musics(:one)
    SavedMusic.create!(user: user, music: music)
    
    duplicate = SavedMusic.new(user: user, music: music)
    assert_not duplicate.valid?
  end
end
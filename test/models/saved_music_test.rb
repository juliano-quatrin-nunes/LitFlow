# == Schema Information
#
# Table name: saved_musics
# Database name: primary
#
#  id            :bigint           not null, primary key
#  preferred_key :string
#  remarks       :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  music_id      :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_saved_musics_on_music_id  (music_id)
#  index_saved_musics_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (music_id => repertoire_musics.id)
#  fk_rails_...  (user_id => users.id)
#
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

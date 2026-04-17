# == Schema Information
#
# Table name: repertoire_musics
# Database name: primary
#
#  id           :bigint           not null, primary key
#  author       :string
#  content_json :jsonb
#  content_raw  :text
#  original_key :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require "test_helper"

class Repertoire::MusicTest < ActiveSupport::TestCase
  test "should not save music without title" do
    music = Repertoire::Music.new(author: "Test Author")
    assert_not music.save, "Saved the music without a title"
  end

  test "should save music with valid attributes" do
    music = Repertoire::Music.new(title: "Test Song", author: "Test Author", original_key: "E")
    assert music.save
  end
end

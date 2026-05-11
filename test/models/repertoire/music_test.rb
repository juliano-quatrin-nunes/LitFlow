# == Schema Information
#
# Table name: repertoire_musics
# Database name: primary
#
#  id           :bigint           not null, primary key
#  content_json :jsonb
#  content_raw  :text
#  original_key :string
#  slug         :string
#  title        :string
#  youtube_url  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  author_id    :bigint           not null
#
# Indexes
#
#  index_repertoire_musics_on_author_id  (author_id)
#  index_repertoire_musics_on_slug       (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (author_id => repertoire_authors.id)
#
require "test_helper"

class Repertoire::MusicTest < ActiveSupport::TestCase
  test "should not save music without title" do
    music = Repertoire::Music.new(author: repertoire_authors(:padre_jonas))
    assert_not music.save, "Saved the music without a title"
  end

  test "should save music with valid attributes" do
    music = Repertoire::Music.new(title: "Test Song", author: repertoire_authors(:padre_jonas), original_key: "E")
    assert music.save
  end

  test "can associate with liturgical seasons and mass parts" do
    music = repertoire_musics(:one)
    season = repertoire_liturgical_seasons(:one)
    part = repertoire_mass_parts(:one)

    music.liturgical_seasons << season
    music.mass_parts << part

    assert_includes music.liturgical_seasons, season
    assert_includes music.mass_parts, part
  end
end

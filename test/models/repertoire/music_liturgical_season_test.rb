# == Schema Information
#
# Table name: repertoire_music_liturgical_seasons
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  liturgical_season_id :bigint           not null
#  music_id             :bigint           not null
#
# Indexes
#
#  idx_on_liturgical_season_id_7436bfb8df                 (liturgical_season_id)
#  index_repertoire_music_liturgical_seasons_on_music_id  (music_id)
#
# Foreign Keys
#
#  fk_rails_...  (liturgical_season_id => repertoire_liturgical_seasons.id)
#  fk_rails_...  (music_id => repertoire_musics.id)
#
require "test_helper"

class Repertoire::MusicLiturgicalSeasonTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

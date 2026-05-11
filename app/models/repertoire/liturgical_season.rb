# == Schema Information
#
# Table name: repertoire_liturgical_seasons
# Database name: primary
#
#  id         :bigint           not null, primary key
#  color      :string
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_repertoire_liturgical_seasons_on_slug  (slug) UNIQUE
#
class Repertoire::LiturgicalSeason < ApplicationRecord
  has_many :music_liturgical_seasons, class_name: "Repertoire::MusicLiturgicalSeason", dependent: :destroy
  has_many :musics, through: :music_liturgical_seasons, class_name: "Repertoire::Music"
end

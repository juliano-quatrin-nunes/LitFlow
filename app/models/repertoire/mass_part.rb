# == Schema Information
#
# Table name: repertoire_mass_parts
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string
#  position   :integer
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_repertoire_mass_parts_on_slug  (slug) UNIQUE
#
class Repertoire::MassPart < ApplicationRecord
  has_many :music_mass_parts, class_name: "Repertoire::MusicMassPart", dependent: :destroy
  has_many :musics, through: :music_mass_parts, class_name: "Repertoire::Music"
end

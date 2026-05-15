# == Schema Information
#
# Table name: setlist_items
# Database name: primary
#
#  id           :bigint           not null, primary key
#  key          :string
#  position     :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  mass_part_id :bigint
#  music_id     :bigint           not null
#  setlist_id   :bigint           not null
#
# Indexes
#
#  index_setlist_items_on_mass_part_id  (mass_part_id)
#  index_setlist_items_on_music_id      (music_id)
#  index_setlist_items_on_setlist_id    (setlist_id)
#
# Foreign Keys
#
#  fk_rails_...  (mass_part_id => repertoire_mass_parts.id)
#  fk_rails_...  (music_id => repertoire_musics.id)
#  fk_rails_...  (setlist_id => setlists.id)
#
class SetlistItem < ApplicationRecord
  belongs_to :setlist
  belongs_to :music, class_name: "Repertoire::Music"
  belongs_to :mass_part, class_name: "Repertoire::MassPart", optional: true

  before_create :set_position

  private

  def set_position
    self.position = setlist.items.maximum(:position).to_i + 1
  end
end

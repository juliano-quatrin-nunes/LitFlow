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
class SavedMusic < ApplicationRecord
  belongs_to :user
  belongs_to :music, class_name: "Repertoire::Music"

  validates :music_id, uniqueness: { scope: :user_id }
end

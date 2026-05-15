# == Schema Information
#
# Table name: setlists
# Database name: primary
#
#  id           :bigint           not null, primary key
#  date         :date
#  location     :string
#  name         :string           not null
#  setlist_type :integer          default("missa"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_setlists_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Setlist < ApplicationRecord
  belongs_to :user
  has_many :items, class_name: "SetlistItem", dependent: :destroy

  enum :setlist_type, {
    missa: 0,
    evento: 1,
    ensaio: 2,
    outro: 3
  }

  validates :name, presence: true
end

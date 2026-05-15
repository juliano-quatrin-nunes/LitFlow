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
#  uid          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_setlists_on_uid      (uid) UNIQUE
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

  before_validation :assign_uid, on: :create

  def missa_slots
    return nil unless missa?

    parts = Repertoire::MassPart.order(:position).to_a
    grouped = items.includes(:music).order(:position).group_by(&:mass_part_id)
    parts.index_with { |part| grouped[part.id] || [] }
  end

  private

  def assign_uid
    return if uid.present?

    loop do
      candidate = SecureRandom.urlsafe_base64(16)
      unless self.class.exists?(uid: candidate)
        self.uid = candidate
        break
      end
    end
  end
end

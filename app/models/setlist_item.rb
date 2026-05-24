# == Schema Information
#
# Table name: setlist_items
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  item_type               :string           not null
#  key                     :string
#  position                :integer          default(0), not null
#  slide_sequence_override :jsonb
#  slides_json_override    :jsonb
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  item_id                 :bigint           not null
#  mass_part_id            :bigint
#  setlist_id              :bigint           not null
#
# Indexes
#
#  index_setlist_items_on_item_type_and_item_id  (item_type,item_id)
#  index_setlist_items_on_mass_part_id           (mass_part_id)
#  index_setlist_items_on_setlist_id             (setlist_id)
#
# Foreign Keys
#
#  fk_rails_...  (mass_part_id => repertoire_mass_parts.id)
#  fk_rails_...  (setlist_id => setlists.id)
#
class SetlistItem < ApplicationRecord
  ALLOWED_ITEM_TYPES = %w[Repertoire::Music].freeze

  belongs_to :setlist
  belongs_to :item, polymorphic: true
  belongs_to :mass_part, class_name: "Repertoire::MassPart", optional: true

  validates :item_type, inclusion: { in: ALLOWED_ITEM_TYPES }
  validates :key, absence: true, unless: :music_item?

  before_create :set_position
  after_save :clear_setlist_pptx_fingerprint_on_override_change
  after_destroy :clear_setlist_pptx_fingerprint

  def music
    item if item.is_a?(Repertoire::Music)
  end

  def music=(value)
    self.item = value
  end

  def effective_slides_json
    slides_json_override.presence || item.slide_deck.slides_json
  end

  def effective_slide_sequence
    slide_sequence_override.presence || item.slide_deck.slide_sequence
  end

  private

  def music_item?
    item.is_a?(Repertoire::Music)
  end

  def set_position
    self.position = setlist.items.maximum(:position).to_i + 1
  end

  def clear_setlist_pptx_fingerprint_on_override_change
    return unless saved_change_to_slides_json_override? ||
                  saved_change_to_slide_sequence_override? ||
                  saved_change_to_id? ||
                  saved_change_to_position?
    clear_setlist_pptx_fingerprint
  end

  def clear_setlist_pptx_fingerprint
    return unless setlist&.has_attribute?(:pptx_fingerprint)
    return if setlist.pptx_fingerprint.nil?
    setlist.update_column(:pptx_fingerprint, nil)
  end
end

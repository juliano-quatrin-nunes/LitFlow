# == Schema Information
#
# Table name: slide_decks
# Database name: primary
#
#  id                    :bigint           not null, primary key
#  pptx_fingerprint      :string
#  slide_sequence        :jsonb            not null
#  slideable_type        :string           not null
#  slides_generated_from :string
#  slides_json           :jsonb            not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  slideable_id          :bigint           not null
#
# Indexes
#
#  index_slide_decks_on_slideable_type_and_slideable_id  (slideable_type,slideable_id) UNIQUE
#
class SlideDeck < ApplicationRecord
  belongs_to :slideable, polymorphic: true

  alias_attribute :sections, :slides_json

  has_one_attached :pptx

  broadcasts_to ->(deck) { "slide_deck_#{deck.id}" }

  after_save :clear_pptx_fingerprint_on_content_change

  def slides_json=(value)
    super(parse_jsonb_input(value))
  end

  def slide_sequence=(value)
    super(parse_jsonb_input(value))
  end

  private

  def parse_jsonb_input(value)
    return value unless value.is_a?(String)
    JSON.parse(value)
  rescue JSON::ParserError
    value
  end

  def clear_pptx_fingerprint_on_content_change
    return unless saved_change_to_slides_json? || saved_change_to_slide_sequence?
    return if pptx_fingerprint.nil?

    update_column(:pptx_fingerprint, nil)
  end
end

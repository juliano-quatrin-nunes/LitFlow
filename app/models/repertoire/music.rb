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
class Repertoire::Music < ApplicationRecord
  belongs_to :author, class_name: "Repertoire::Author"

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :author_id }

  before_validation :generate_slug, if: -> { title.present? && slug.blank? }

  before_save :parse_content

  def to_param
    slug
  end

  def author_name
    author&.name
  end

  def content_json
    data = super.present? ? super : nil
    
    if data.nil? && content_raw.present?
      result = Repertoire::MusicParserService.call(content_raw)
      data = result[:json]
    end

    return [] if data.blank?
    
    # Deeply convert to indifferent access
    data.map { |section| section.with_indifferent_access }
  end

  private

  def generate_slug
    self.slug = title.parameterize
  end

  def parse_content
    return if content_raw.blank?

    result = Repertoire::MusicParserService.call(content_raw)
    self.content_raw = result[:raw]
    self.content_json = result[:json]
  end
end

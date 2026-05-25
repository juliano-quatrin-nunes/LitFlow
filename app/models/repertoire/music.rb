# == Schema Information
#
# Table name: repertoire_musics
# Database name: primary
#
#  id                :bigint           not null, primary key
#  cifra_fingerprint :string
#  content_json      :jsonb
#  content_raw       :text
#  original_key      :string
#  slug              :string
#  title             :string
#  youtube_url       :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  author_id         :bigint           not null
#
# Indexes
#
#  index_repertoire_musics_on_author_id          (author_id)
#  index_repertoire_musics_on_cifra_fingerprint  (cifra_fingerprint)
#  index_repertoire_musics_on_slug               (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (author_id => repertoire_authors.id)
#
class Repertoire::Music < ApplicationRecord
  include Slideable

  belongs_to :author, class_name: "Repertoire::Author"
  accepts_nested_attributes_for :slide_deck, update_only: true

  has_many :music_liturgical_seasons, class_name: "Repertoire::MusicLiturgicalSeason", dependent: :destroy
  has_many :liturgical_seasons, through: :music_liturgical_seasons

  has_many :music_mass_parts, class_name: "Repertoire::MusicMassPart", dependent: :destroy
  has_many :mass_parts, through: :music_mass_parts

  has_many :setlist_items, as: :item, dependent: :destroy

  has_one_attached :cifra_pdf
  has_one_attached :cifra_docx

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

  def youtube_video_id
    return nil if youtube_url.blank?

    # Handle various YouTube URL formats:
    # - Standard: https://www.youtube.com/watch?v=VIDEO_ID
    # - Short: https://youtu.be/VIDEO_ID
    # - Embed: https://www.youtube.com/embed/VIDEO_ID
    # - With playlists/params: https://www.youtube.com/watch?v=VIDEO_ID&list=...
    if youtube_url =~ /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/
      $1
    end
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

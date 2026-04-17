# == Schema Information
#
# Table name: repertoire_musics
# Database name: primary
#
#  id           :bigint           not null, primary key
#  author       :string
#  content_json :jsonb
#  content_raw  :text
#  original_key :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Repertoire::Music < ApplicationRecord
  validates :title, presence: true

  before_save :parse_content

  private

  def parse_content
    return if content_raw.blank?

    result = Repertoire::MusicParserService.call(content_raw)
    self.content_raw = result[:raw]
    self.content_json = result[:json]
  end
end

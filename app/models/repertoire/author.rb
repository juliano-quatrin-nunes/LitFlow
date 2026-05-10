# == Schema Information
#
# Table name: repertoire_authors
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_repertoire_authors_on_name  (name) UNIQUE
#  index_repertoire_authors_on_slug  (slug) UNIQUE
#
class Repertoire::Author < ApplicationRecord
  has_many :musics, class_name: "Repertoire::Music", dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { name.present? && slug.blank? }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end

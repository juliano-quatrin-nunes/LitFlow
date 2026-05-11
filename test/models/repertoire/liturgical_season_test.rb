# == Schema Information
#
# Table name: repertoire_liturgical_seasons
# Database name: primary
#
#  id         :bigint           not null, primary key
#  color      :string
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_repertoire_liturgical_seasons_on_slug  (slug) UNIQUE
#
require "test_helper"

class Repertoire::LiturgicalSeasonTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

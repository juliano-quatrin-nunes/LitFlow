# == Schema Information
#
# Table name: repertoire_mass_parts
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string
#  position   :integer
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_repertoire_mass_parts_on_slug  (slug) UNIQUE
#
require "test_helper"

class Repertoire::MassPartTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

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
require "test_helper"

class SetlistTest < ActiveSupport::TestCase
  setup do
    @user = users(:user)
  end

  test "missa setlist returns ordered slots for every mass part" do
    setlist = Setlist.create!(user: @user, name: "Missa Teste", setlist_type: "missa")

    slots = setlist.missa_slots

    expected_parts = Repertoire::MassPart.order(:position).pluck(:name)
    assert_equal expected_parts, slots.keys.map(&:name)
    slots.each_value { |items| assert_equal [], items }
  end

  test "missa setlist groups items by mass_part" do
    setlist = Setlist.create!(user: @user, name: "Missa Teste", setlist_type: "missa")
    entrada = repertoire_mass_parts(:two) # Entrada
    comunhao = repertoire_mass_parts(:one) # Comunhão

    music = repertoire_musics(:one)
    item_entrada = setlist.items.create!(music: music, mass_part: entrada, key: "G")
    item_comunhao = setlist.items.create!(music: music, mass_part: comunhao, key: "A")

    slots = setlist.missa_slots

    assert_includes slots[entrada], item_entrada
    assert_includes slots[comunhao], item_comunhao
  end

  test "non-missa setlist does not expose missa_slots" do
    setlist = Setlist.create!(user: @user, name: "Evento Teste", setlist_type: "evento")

    assert_nil setlist.missa_slots
  end

  test "setlist receives a unique uid on creation" do
    setlist = Setlist.create!(user: @user, name: "Missa Teste", setlist_type: "missa")

    assert setlist.uid.present?
    assert_operator setlist.uid.length, :>=, 16
  end

  test "uid is preserved across saves" do
    setlist = Setlist.create!(user: @user, name: "Missa Teste", setlist_type: "missa")
    uid = setlist.uid

    setlist.update!(name: "Renomeada")
    assert_equal uid, setlist.reload.uid
  end
end

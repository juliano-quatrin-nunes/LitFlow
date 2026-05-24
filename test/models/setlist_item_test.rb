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
require "test_helper"

class SetlistItemTest < ActiveSupport::TestCase
  setup do
    @user = users(:user)
    @setlist = Setlist.create!(user: @user, name: "Missa Teste", setlist_type: "missa")
    @music = repertoire_musics(:one)
  end

  test "belongs_to polymorphic :item resolves to the underlying Repertoire::Music" do
    item = @setlist.items.create!(item: @music)

    assert_equal "Repertoire::Music", item.item_type
    assert_equal @music.id, item.item_id
    assert_kind_of Repertoire::Music, item.item
    assert_equal @music, item.item
  end

  test "item_type must be in the whitelist" do
    item = @setlist.items.new(item_type: "Repertoire::Author", item_id: @music.author_id)

    assert_not item.valid?
    assert_includes item.errors[:item_type], "is not included in the list"
  end

  test "key is allowed only when item is a Repertoire::Music" do
    item = @setlist.items.new(item: @music, key: "G")
    assert item.valid?, "key should be allowed on Music items"

    other = @setlist.items.new(item: @music, key: "G")
    other.define_singleton_method(:music_item?) { false }
    assert_not other.valid?
    assert_includes other.errors[:key], "must be blank"
  end

  test "music compatibility shim returns the underlying Repertoire::Music" do
    item = @setlist.items.create!(item: @music)
    assert_equal @music, item.music
  end

  test "destroying the underlying Music cascades and removes its setlist_items" do
    music = Repertoire::Music.create!(title: "Cascade Probe", author: repertoire_authors(:padre_jonas), content_raw: "[E]x")
    item = @setlist.items.create!(item: music)

    assert_difference("SetlistItem.count", -1) do
      music.destroy!
    end

    assert_nil SetlistItem.find_by(id: item.id)
  end

  test "effective_slides_json falls back to the slideable's slides_json when override is null" do
    item = @setlist.items.create!(item: @music)

    assert_nil item.slides_json_override
    assert_equal @music.slide_deck.slides_json, item.effective_slides_json
  end

  test "effective_slides_json returns override when present" do
    custom = [ { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "linha custom" ] } ]
    item = @setlist.items.create!(item: @music, slides_json_override: custom)

    assert_equal custom, item.effective_slides_json
  end

  test "effective_slide_sequence falls back to slideable and returns override when present" do
    item = @setlist.items.create!(item: @music)
    assert_equal @music.slide_deck.slide_sequence, item.effective_slide_sequence

    item.update!(slide_sequence_override: [ "verse_1", "verse_1" ])
    assert_equal [ "verse_1", "verse_1" ], item.effective_slide_sequence
  end

  test "underlying Music edit propagates to items whose override is null" do
    item = @setlist.items.create!(item: @music)
    new_sections = [ { "id" => "verse_99", "type" => "verse", "label" => "Estrofe 99", "lines" => [ "novo" ] } ]
    @music.slide_deck.update!(slides_json: new_sections)

    assert_equal new_sections, item.reload.effective_slides_json
  end

  test "underlying Music edit does not change effective slides for items with non-null override" do
    override = [ { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "linha custom" ] } ]
    item = @setlist.items.create!(item: @music, slides_json_override: override)
    @music.slide_deck.update!(slides_json: [ { "id" => "verse_99", "type" => "verse", "label" => "X", "lines" => [ "y" ] } ])

    assert_equal override, item.reload.effective_slides_json
  end

  test "changing slides_json_override clears the parent setlist's pptx_fingerprint" do
    item = @setlist.items.create!(item: @music)
    @setlist.update_column(:pptx_fingerprint, "deadbeef")

    item.update!(slides_json_override: [ { "id" => "verse_1", "type" => "verse", "label" => "x", "lines" => [ "y" ] } ])

    assert_nil @setlist.reload.pptx_fingerprint
  end

  test "changing slide_sequence_override clears the parent setlist's pptx_fingerprint" do
    item = @setlist.items.create!(item: @music)
    @setlist.update_column(:pptx_fingerprint, "cafebabe")

    item.update!(slide_sequence_override: [ "verse_1" ])

    assert_nil @setlist.reload.pptx_fingerprint
  end
end

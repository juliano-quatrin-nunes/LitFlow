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
require "test_helper"

class SlideDeckTest < ActiveSupport::TestCase
  test "Repertoire::Music create with content_raw auto-creates a slide_deck with populated slides_json and slide_sequence" do
    cifra = <<~TEXT
      E                  C#m
      Vem e eu mostrarei que o meu caminho
    TEXT

    music = Repertoire::Music.create!(
      title: "Tracer Song",
      author: repertoire_authors(:padre_jonas),
      content_raw: cifra
    )

    deck = music.slide_deck
    assert_not_nil deck
    assert_not_empty deck.slides_json
    assert_equal [ "verse_1" ], deck.slide_sequence
    assert_equal Digest::SHA1.hexdigest(music.content_raw), deck.slides_generated_from
  end

  test "Music create with blank content_raw still creates an empty slide_deck row" do
    music = Repertoire::Music.create!(
      title: "Empty Cifra Song",
      author: repertoire_authors(:padre_jonas)
    )

    deck = music.slide_deck
    assert_not_nil deck
    assert_equal [], deck.slides_json
    assert_equal [], deck.slide_sequence
    assert_nil deck.slides_generated_from
  end

  test "polymorphic association resolves back to a Repertoire::Music" do
    music = Repertoire::Music.create!(
      title: "Polymorphic Probe",
      author: repertoire_authors(:padre_jonas),
      content_raw: "Just a line"
    )

    deck = SlideDeck.find(music.slide_deck.id)
    assert_kind_of Repertoire::Music, deck.slideable
    assert_equal music.id, deck.slideable.id
  end

  test "sections is aliased to slides_json" do
    music = Repertoire::Music.create!(
      title: "Alias Probe",
      author: repertoire_authors(:padre_jonas),
      content_raw: "Just a line"
    )

    assert_equal music.slide_deck.slides_json, music.slide_deck.sections
  end

  test "saving with mutated slides_json clears pptx_fingerprint" do
    music = Repertoire::Music.create!(
      title: "Fingerprint Probe",
      author: repertoire_authors(:padre_jonas),
      content_raw: "Line one"
    )
    deck = music.slide_deck
    deck.update_column(:pptx_fingerprint, "deadbeef")

    deck.slides_json = deck.slides_json + [ { "id" => "verse_2", "type" => "verse", "label" => "Estrofe 2", "lines" => [ "x" ] } ]
    deck.save!

    assert_nil deck.reload.pptx_fingerprint
  end

  test "saving with mutated slide_sequence clears pptx_fingerprint" do
    music = Repertoire::Music.create!(
      title: "Sequence Fingerprint Probe",
      author: repertoire_authors(:padre_jonas),
      content_raw: "Line one"
    )
    deck = music.slide_deck
    deck.update_column(:pptx_fingerprint, "cafebabe")

    deck.slide_sequence = []
    deck.save!

    assert_nil deck.reload.pptx_fingerprint
  end

  test "responds to broadcasts_to declaration so the music show frame receives updates" do
    music = Repertoire::Music.create!(
      title: "Broadcast Probe",
      author: repertoire_authors(:padre_jonas),
      content_raw: "Line one"
    )
    deck = music.slide_deck

    # broadcasts_to registers after_commit callbacks defined in turbo-rails' Broadcastable.
    broadcast_callback_sources = SlideDeck._commit_callbacks.map { |c| c.filter.source_location.first if c.filter.respond_to?(:source_location) }.compact
    assert broadcast_callback_sources.any? { |path| path.include?("turbo") && path.include?("broadcastable") },
           "expected SlideDeck to register turbo broadcastable commit callbacks via broadcasts_to"
  end

  test "editing a Music's slide_deck clears pptx_fingerprint on every Setlist whose items point at that Music" do
    user = users(:user)
    music = repertoire_musics(:one)
    setlist_a = Setlist.create!(user: user, name: "A", setlist_type: "evento")
    setlist_b = Setlist.create!(user: user, name: "B", setlist_type: "evento")
    setlist_c = Setlist.create!(user: user, name: "C", setlist_type: "evento")
    setlist_a.items.create!(item: music)
    setlist_b.items.create!(item: music)
    setlist_a.update_column(:pptx_fingerprint, "aaa")
    setlist_b.update_column(:pptx_fingerprint, "bbb")
    setlist_c.update_column(:pptx_fingerprint, "ccc")

    music.slide_deck.update!(slides_json: music.slide_deck.slides_json + [ { "id" => "verse_2", "type" => "verse", "label" => "x", "lines" => [ "y" ] } ])

    assert_nil setlist_a.reload.pptx_fingerprint, "setlist A (has item) should be cleared"
    assert_nil setlist_b.reload.pptx_fingerprint, "setlist B (has item) should be cleared"
    assert_equal "ccc", setlist_c.reload.pptx_fingerprint, "setlist C (no item) should be untouched"
  end

  test "saving without slides_json or slide_sequence changes leaves pptx_fingerprint intact" do
    music = Repertoire::Music.create!(
      title: "Untouched Fingerprint Probe",
      author: repertoire_authors(:padre_jonas),
      content_raw: "Line one"
    )
    deck = music.slide_deck
    deck.update_column(:pptx_fingerprint, "stable123")

    deck.touch

    assert_equal "stable123", deck.reload.pptx_fingerprint
  end
end

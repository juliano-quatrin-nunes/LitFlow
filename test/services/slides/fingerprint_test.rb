require "test_helper"

class Slides::FingerprintTest < ActiveSupport::TestCase
  SLIDES_JSON = [
    { "id" => "verse_1", "type" => "verse", "label" => "Estrofe 1", "lines" => [ "Vem e eu mostrarei" ] },
    { "id" => "chorus_1", "type" => "chorus", "label" => "Refrão", "lines" => [ "AMÉM", "AMÉM" ] }
  ].freeze
  SEQUENCE = [ "verse_1", "chorus_1" ].freeze

  test "identical inputs produce identical hashes" do
    a = Slides::Fingerprint.call(SLIDES_JSON, SEQUENCE, "v1")
    b = Slides::Fingerprint.call(SLIDES_JSON, SEQUENCE, "v1")

    assert_equal a, b
  end

  test "hash is a 40-character hex SHA1" do
    digest = Slides::Fingerprint.call(SLIDES_JSON, SEQUENCE, "v1")

    assert_match(/\A[0-9a-f]{40}\z/, digest)
  end

  test "reordering hash keys inside slides_json does not change the hash" do
    reordered = SLIDES_JSON.map do |section|
      # Reverse the key order so the JSON serialization differs
      section.to_a.reverse.to_h
    end

    original = Slides::Fingerprint.call(SLIDES_JSON, SEQUENCE, "v1")
    swapped = Slides::Fingerprint.call(reordered, SEQUENCE, "v1")

    assert_equal original, swapped
  end

  test "changing a single line changes the hash" do
    mutated = SLIDES_JSON.deep_dup
    mutated[0]["lines"] = [ "Linha alterada" ]

    refute_equal Slides::Fingerprint.call(SLIDES_JSON, SEQUENCE, "v1"),
                 Slides::Fingerprint.call(mutated, SEQUENCE, "v1")
  end

  test "changing the theme version changes the hash" do
    refute_equal Slides::Fingerprint.call(SLIDES_JSON, SEQUENCE, "v1"),
                 Slides::Fingerprint.call(SLIDES_JSON, SEQUENCE, "v2")
  end

  test "changing the sequence changes the hash" do
    refute_equal Slides::Fingerprint.call(SLIDES_JSON, SEQUENCE, "v1"),
                 Slides::Fingerprint.call(SLIDES_JSON, [ "chorus_1", "verse_1" ], "v1")
  end

  test "string keys and symbol keys produce the same hash" do
    symbol_keyed = SLIDES_JSON.map { |s| s.transform_keys(&:to_sym) }

    assert_equal Slides::Fingerprint.call(SLIDES_JSON, SEQUENCE, "v1"),
                 Slides::Fingerprint.call(symbol_keyed, SEQUENCE, "v1")
  end
end

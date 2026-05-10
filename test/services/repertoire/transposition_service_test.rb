require "test_helper"

class Repertoire::TranspositionServiceTest < ActiveSupport::TestCase
  setup do
    @sample_json = [
      {
        type: "verse",
        lines: [
          {
            parts: [
              { chord: "C", lyric: "Vem e eu " },
              { chord: "G/B", lyric: "mostrarei" }
            ]
          },
          {
            parts: [
              { chord: "Am7", lyric: "que o meu " },
              { chord: "F", lyric: "caminho" }
            ]
          }
        ]
      }
    ]
  end

  test "should transpose up by two semitones (C to D)" do
    result = Repertoire::TranspositionService.call(@sample_json, "C", "D")

    # C -> D
    # G/B -> A/C#
    # Am7 -> Bm7
    # F -> G
    expected_chords = ["D", "A/C#", "Bm7", "G"]
    actual_chords = result[0][:lines].flat_map { |l| l[:parts].map { |p| p[:chord] } }

    assert_equal expected_chords, actual_chords
  end

  test "should transpose down by one semitone (C to B)" do
    result = Repertoire::TranspositionService.call(@sample_json, "C", "B")

    # C -> B
    # G/B -> F#/A#
    # Am7 -> G#m7
    # F -> E
    expected_chords = ["B", "F#/A#", "G#m7", "E"]
    actual_chords = result[0][:lines].flat_map { |l| l[:parts].map { |p| p[:chord] } }

    assert_equal expected_chords, actual_chords
  end

  test "should handle enharmonics correctly when transposing to a flat key (C to F)" do
    # In F major, we prefer Bb over A#
    input = [
      {
        lines: [
          { parts: [ { chord: "E", lyric: "test" } ] }
        ]
      }
    ]
    # E + 5 semitones (C to F) = A# or Bb. Target F is in FLAT_KEYS.
    result = Repertoire::TranspositionService.call(input, "C", "F")
    assert_equal "A", result[0][:lines][0][:parts][0][:chord] # Wait, E+5 = A. Bad example.

    # Let's try G to F (-2 semitones)
    # G -> F
    # B -> A (Wait, B-2 = A)
    # C -> Bb
    input = [ { lines: [ { parts: [ { chord: "C", lyric: "test" } ] } ] } ]
    result = Repertoire::TranspositionService.call(input, "G", "F")
    assert_equal "Bb", result[0][:lines][0][:parts][0][:chord]
  end

  test "should handle complex suffixes" do
    input = [ { lines: [ { parts: [ { chord: "F#m7(b5)", lyric: "test" } ] } ] } ]
    # F#m7(b5) + 1 semitone = Gm7(b5)
    result = Repertoire::TranspositionService.call(input, "C", "C#")
    assert_equal "Gm7(b5)", result[0][:lines][0][:parts][0][:chord]
  end

  test "should return original json if keys are the same" do
    result = Repertoire::TranspositionService.call(@sample_json, "C", "C")
    assert_equal @sample_json, result
  end

  test "should handle minor keys in from/to parameters" do
    # Am to Bm is +2 semitones
    input = [ { lines: [ { parts: [ { chord: "Am", lyric: "test" } ] } ] } ]
    result = Repertoire::TranspositionService.call(input, "Am", "Bm")
    assert_equal "Bm", result[0][:lines][0][:parts][0][:chord]
  end

  test "should transpose bass notes correctly" do
    input = [ { lines: [ { parts: [ { chord: "D/F#", lyric: "test" } ] } ] } ]
    # D/F# + 2 semitones = E/G#
    result = Repertoire::TranspositionService.call(input, "C", "D")
    assert_equal "E/G#", result[0][:lines][0][:parts][0][:chord]
  end
end

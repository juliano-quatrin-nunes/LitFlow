module Repertoire
  class TranspositionService
    CHROMATIC_SCALE_SHARPS = %w[C C# D D# E F F# G G# A A# B].freeze
    CHROMATIC_SCALE_FLATS  = %w[C Db D Eb E F Gb G Ab A Bb B].freeze

    FLAT_KEYS = %w[F Bb Eb Ab Db Gb Dm Gm Cm Fm Bbm Ebm].freeze

    CHORD_PARSER_REGEX = /^([A-G][b#]?)(.*?)(?:\/([A-G][b#]?))?$/

    CHROMATIC_KEYS = %w[C Db D Eb E F F# G Ab A Bb B].freeze

    def self.transpose_key(key, offset)
      root = key.match(/^([A-G][b#]?)/)[1]
      suffix = key[root.length..]

      current_index = CHROMATIC_SCALE_SHARPS.index(root) || CHROMATIC_SCALE_FLATS.index(root)
      target_index = (current_index + offset) % 12

      new_root = if FLAT_KEYS.include?(key)
                   CHROMATIC_SCALE_FLATS[target_index]
      else
                   CHROMATIC_SCALE_SHARPS[target_index]
      end

      "#{new_root}#{suffix}"
    end

    def self.call(content_json, from_key, to_key)
      new(content_json, from_key, to_key).call
    end

    def initialize(content_json, from_key, to_key)
      @content_json = content_json || []
      @from_key = from_key
      @to_key = to_key
      @offset = calculate_offset(from_key, to_key)
      @use_flats = prefer_flats?(to_key)
    end

    def call
      result = if @offset.zero?
                 @content_json
               else
                 @content_json.map do |section|
                   transpose_section(section)
                 end
               end

      result.map(&:with_indifferent_access)
    end

    private

    def transpose_section(section)
      section = section.deep_dup
      lines = section["lines"] || section[:lines]
      lines.each do |line|
        parts = line["parts"] || line[:parts]
        parts.each do |part|
          chord = part["chord"] || part[:chord]
          if chord.present?
            new_chord = transpose_chord(chord)
            if part.key?("chord")
              part["chord"] = new_chord
            else
              part[:chord] = new_chord
            end
          end
        end
      end
      section
    end

    def transpose_chord(chord_string)
      match = chord_string.match(CHORD_PARSER_REGEX)
      return chord_string unless match

      root = match[1]
      suffix = match[2]
      bass = match[3]

      transposed_root = transpose_note(root)
      transposed_bass = bass ? "/#{transpose_note(bass)}" : ""

      "#{transposed_root}#{suffix}#{transposed_bass}"
    end

    def transpose_note(note)
      current_semitone = note_to_semitone(note)
      target_semitone = (current_semitone + @offset) % 12
      semitone_to_note(target_semitone)
    end

    def calculate_offset(from, to)
      from_root = from.match(/^([A-G][b#]?)/)[1]
      to_root = to.match(/^([A-G][b#]?)/)[1]

      (note_to_semitone(to_root) - note_to_semitone(from_root)) % 12
    end

    def note_to_semitone(note)
      index = CHROMATIC_SCALE_SHARPS.index(note) || CHROMATIC_SCALE_FLATS.index(note)
      raise "Invalid note: #{note}" unless index
      index
    end

    def semitone_to_note(semitone)
      scale = @use_flats ? CHROMATIC_SCALE_FLATS : CHROMATIC_SCALE_SHARPS
      scale[semitone]
    end

    def prefer_flats?(key)
      FLAT_KEYS.include?(key)
    end
  end
end

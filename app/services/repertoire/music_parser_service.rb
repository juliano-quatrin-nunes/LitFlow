require "strscan"

module Repertoire
  class MusicParserService
    # Improved chord regex
    CHORD_REGEX = %r{[A-G][b#]?(?:m|maj|min|dim|aug|sus|add|7|9|11|13)*(?:/[A-G][b#]?)?}

    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @text = text || ""
    end

    def call
      raw = parse_to_chordpro(@text)
      json = generate_json(raw)
      { raw: raw, json: json }
    end

    private

    def parse_to_chordpro(text)
      lines = text.split("\n")
      result = []

      i = 0
      while i < lines.length
        line = lines[i]

        if is_chordpro_line?(line)
          result << line
          i += 1
          next
        end

        next_line = lines[i + 1]

        if is_chord_line?(line) && next_line && !is_chord_line?(next_line) && !is_chordpro_line?(next_line)
          result << interleave(line, next_line)
          i += 2
        elsif is_chord_line?(line)
          result << wrap_chords(line)
          i += 1
        else
          result << line
          i += 1
        end
      end

      result.join("\n")
    end

    def is_chordpro_line?(line)
      line.match?(/\[[A-G][^\]]*\]/)
    end

    def is_chord_line?(line)
      return false if line.strip.empty?

      # A chord line should mostly contain chords and spaces
      # We split by spaces and check each "word"
      words = line.split(/\s+/)
      words.reject!(&:empty?)
      return false if words.empty?

      chord_count = words.count { |w| is_pure_chord?(w) }
      chord_count.to_f / words.count >= 0.5
    end

    def is_pure_chord?(word)
      # A word is a chord if it matches the regex completely
      word.match?(/^#{CHORD_REGEX}$/)
    end

    def interleave(chord_line, lyric_line)
      chords = []
      # We find all matches and their positions
      # Using a more careful scan to get positions
      pos = 0
      while pos < chord_line.length
        if match = chord_line[pos..].match(CHORD_REGEX)
          actual_pos = pos + match.begin(0)
          chords << { chord: match[0], pos: actual_pos }
          pos = actual_pos + match[0].length
        else
          break
        end
      end

      # Interleave into lyric_line
      result = lyric_line.dup
      offset = 0
      chords.each do |c|
        insert_pos = [ c[:pos] + offset, result.length ].min
        result.insert(insert_pos, "[#{c[:chord]}]")
        offset += c[:chord].length + 2
      end
      result
    end

    def wrap_chords(line)
      # For lines that are only chords, we wrap them but keep spaces
      result = line.dup
      offset = 0
      pos = 0
      while pos < result.length
        if match = result[pos..].match(CHORD_REGEX)
          actual_pos = pos + match.begin(0)
          chord = match[0]
          result.insert(actual_pos, "[")
          result.insert(actual_pos + chord.length + 1, "]")
          pos = actual_pos + chord.length + 2
        else
          break
        end
      end
      result
    end

    def generate_json(chordpro_text)
      chordpro_text.split("\n").map do |line|
        {
          type: "line",
          parts: parse_line_to_fragments(line)
        }
      end
    end

    def parse_line_to_fragments(line)
      fragments = []
      # Matches [CHORD] followed by optional text until next [CHORD] or end of line
      # Also matches text at the beginning of the line before any [CHORD]

      scanner = StringScanner.new(line)

      until scanner.eos?
        if scanner.scan(/\[([^\]]+)\]/)
          chord = scanner[1]
          lyric = scanner.scan(/[^\[]+/) || ""
          fragments << { chord: chord, lyric: lyric }
        else
          lyric = scanner.scan(/[^\[]+/)
          fragments << { lyric: lyric } if lyric
        end
      end

      fragments
    end
  end
end

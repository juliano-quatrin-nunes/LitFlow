require "strscan"

module Repertoire
  class MusicParserService
    # Improved chord regex
    CHORD_REGEX = %r{[A-G][b#]?(?:m|maj|min|dim|aug|sus|add|7|9|11|13)*(?:/[A-G][b#]?)?}
    LABEL_REGEX = /^\[(.+)\]$|^(.+):$/

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

        if is_label?(line) || is_chordpro_line?(line)
          result << line
          i += 1
          next
        end

        next_line = lines[i + 1]

        if is_chord_line?(line) && next_line && next_line.strip.present? && !is_chord_line?(next_line) && !is_label?(next_line) && !is_chordpro_line?(next_line)
          result << interleave(line.gsub(/[()]/, " "), next_line)
          i += 2
        elsif is_chord_line?(line)
          result << wrap_chords(line.gsub(/[()]/, " "))
          i += 1
        else
          result << line
          i += 1
        end
      end

      result.join("\n")
    end

    def is_label?(line)
      text = line.strip
      # A label must be either [Label Content] or Label Content:
      # and it must NOT be a line that looks like it has multiple chords in brackets
      if text.match?(/^\[[^\]]+\]$/)
        label_content = text.match(/^\[(.+)\]$/)[1]
        !is_pure_chord?(label_content)
      elsif text.match?(/^[^:]+:$/)
        # Avoid matching lines that are just chords with a colon (rare but possible)
        label_content = text.match(/^(.+):$/)[1]
        !is_pure_chord?(label_content)
      else
        false
      end
    end

    def is_chordpro_line?(line)
      line.match?(/\[[A-G][^\]]*\]/)
    end

    def is_chord_line?(line)
      clean_line = line.strip.gsub(/[()]/, "")
      return false if clean_line.empty?

      words = clean_line.split(/\s+/)
      words.reject!(&:empty?)
      return false if words.empty?

      chord_count = words.count { |w| is_pure_chord?(w) }
      chord_count.to_f / words.count >= 0.5
    end

    def is_pure_chord?(word)
      word.match?(/^#{CHORD_REGEX}$/)
    end

    def interleave(chord_line, lyric_line)
      chords = []
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
      result = line.dup
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
      lines = chordpro_text.split("\n")
      sections = []
      current_section = nil
      pending_type = nil

      lines.each do |line|
        if line.strip.empty?
          current_section = nil
          next
        end

        if is_label?(line)
          label_text = line.strip.match(LABEL_REGEX).captures.compact.first
          sections << { type: "label", lines: [ { parts: [ { lyric: label_text } ] } ] }
          pending_type = infer_type_from_label(label_text)
          current_section = nil # Ensure next content line starts a new section
          next
        end

        unless current_section
          current_section = { type: pending_type || "unknown", lines: [] }
          sections << current_section
          pending_type = nil
        end

        current_section[:lines] << { parts: parse_line_to_fragments(line) }
      end

      # Post-process sections: refine 'unknown' types and remove empty ones
      sections.each do |s|
        next unless s[:type] == "unknown"
        s[:type] = infer_type_from_content(s)
      end

      sections.reject { |s| s[:lines].empty? }
    end

    def infer_type_from_label(label)
      label = label.downcase
      if label.include?("refrão") || label.include?("chorus")
        "chorus"
      elsif label.include?("intro")
        "intro"
      elsif label.include?("ponte") || label.include?("bridge")
        "bridge"
      elsif label.include?("final") || label.include?("outro")
        "outro"
      else
        "verse"
      end
    end

    def infer_type_from_content(section)
      # Check if any line has real lyrics (not just chords, spaces, or notation symbols)
      has_real_lyrics = section[:lines].any? do |l|
        l[:parts].any? do |p|
          # Remove common notation symbols and check for alphanumeric content
          p[:lyric].gsub(/[()\[\]\s\-_]/, "").present?
        end
      end
      has_real_lyrics ? "verse" : "intro"
    end


    def parse_line_to_fragments(line)
      fragments = []
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

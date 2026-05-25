module Repertoire
  class CifraFormatterService
    def self.call(content_json)
      new(content_json).call
    end

    def self.as_html(content_json)
      new(content_json).as_html
    end

    def initialize(content_json)
      @content_json = content_json
    end

    def call
      sections = @content_json.map do |section|
        if section["type"] == "label"
          label_text = section.dig("lines", 0, "parts", 0, "lyric") || ""
          {
            type: "label",
            label: "[#{label_text}]"
          }
        else
          {
            type: section["type"],
            lines: format_lines(section["lines"] || [])
          }
        end
      end

      { sections: sections }
    end

    def as_html
      html_sections = @content_json.map do |section|
        if section["type"] == "label"
          label_text = section.dig("lines", 0, "parts", 0, "lyric") || ""
          "[#{label_text}]"
        else
          format_html_lines(section["lines"] || []).join("\n")
        end
      end

      "<pre style=\"font-family: 'Roboto Mono', monospace;\">#{html_sections.join("\n\n")}</pre>"
    end

    private

    def format_html_lines(lines)
      lines.map do |line|
        chord_line = ""
        lyric_line = ""

        (line["parts"] || []).each do |part|
          chord = part["chord"] || ""
          lyric = part["lyric"] || ""

          chord_padded = chord.present? ? "#{chord} " : ""
          max_len = [ chord_padded.length, lyric.length ].max

          padding_spaces = " " * (max_len - chord_padded.length)
          if chord.present?
            chord_line += "<b>#{chord}</b> #{padding_spaces}"
          else
            chord_line += " " * max_len
          end

          lyric_line += lyric.ljust(max_len, " ")
        end

        result = []
        result << chord_line.rstrip if chord_line.strip.present? || chord_line.include?("<b>")
        result << lyric_line.rstrip if lyric_line.strip.present?
        result.join("\n")
      end.reject(&:blank?)
    end

    def format_lines(lines)
      lines.map do |line|
        chord_line = ""
        lyric_line = ""

        (line["parts"] || []).each do |part|
          chord = part["chord"] || ""
          lyric = part["lyric"] || ""

          # +1 space after chord to separate from next part if needed
          chord_padded = chord.present? ? "#{chord} " : ""
          max_len = [ chord_padded.length, lyric.length ].max

          chord_line += chord_padded.ljust(max_len, " ")
          lyric_line += lyric.ljust(max_len, " ")
        end

        {
          chord_line: chord_line.rstrip,
          lyric_line: lyric_line.rstrip
        }
      end
    end
  end
end

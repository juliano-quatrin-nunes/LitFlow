module Slides
  class Extractor
    DEFAULT_LABELS = {
      "intro" => ->(_n) { "Intro" },
      "verse" => ->(n) { "Estrofe #{n}" },
      "chorus" => ->(_n) { "Refrão" },
      "bridge" => ->(_n) { "Ponte" },
      "outro" => ->(_n) { "Final" },
      "label" => ->(_n) { "Marcador" }
    }.freeze

    def self.call(content_json)
      new(content_json).call
    end

    def self.default_sequence(slides_json)
      slides_json
        .map { |section| section.with_indifferent_access }
        .reject { |section| section["lines"].blank? }
        .map { |section| section["id"] }
    end

    def initialize(content_json)
      @content_json = Array(content_json).map { |s| s.with_indifferent_access }
    end

    def call
      counters = Hash.new(0)

      @content_json.map do |section|
        type = section["type"].to_s
        counters[type] += 1
        index = counters[type]

        {
          id: "#{type}_#{index}",
          type: type,
          label: DEFAULT_LABELS.fetch(type).call(index),
          lines: extract_lines(section)
        }.with_indifferent_access
      end
    end

    private

    def extract_lines(section)
      return [] if section["type"].to_s == "label"

      Array(section["lines"]).filter_map do |line|
        raw_lyric = Array(line["parts"]).map { |p| p["lyric"].to_s }.join.strip
        next if raw_lyric.empty?

        stripped = Slides::PhoneticStrip.call(raw_lyric)
        stripped.presence
      end
    end
  end
end

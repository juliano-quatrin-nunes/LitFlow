require "open3"
require "timeout"

module Slides
  class PptxRenderer
    DEFAULT_TIMEOUT_SECONDS = 30

    def self.call(slide_deck, timeout: DEFAULT_TIMEOUT_SECONDS)
      new(slide_deck, timeout: timeout).call
    end

    def self.render_slides(slides, timeout: DEFAULT_TIMEOUT_SECONDS)
      payload = { "theme" => Slides::Theme::V1.to_h, "slides" => slides }
      shell_out(payload, timeout: timeout)
    end

    def self.shell_out(payload, timeout: DEFAULT_TIMEOUT_SECONDS)
      stdout, stderr, status = Timeout.timeout(timeout) do
        Open3.capture3(
          "python3",
          Rails.root.join("bin/render_pptx.py").to_s,
          stdin_data: payload.to_json,
          binmode: true
        )
      end

      unless status.success?
        raise RenderError, "render_pptx.py failed (exit #{status.exitstatus}): #{stderr.to_s.strip}"
      end

      stdout
    end

    def initialize(slide_deck, timeout: DEFAULT_TIMEOUT_SECONDS)
      @slide_deck = slide_deck
      @timeout = timeout
    end

    def call
      self.class.shell_out(build_payload, timeout: @timeout)
    end

    private

    def build_payload
      {
        "theme" => Slides::Theme::V1.to_h,
        "slides" => physical_slides
      }
    end

    def physical_slides
      sections_by_id = @slide_deck.slides_json.each_with_object({}) do |section, memo|
        section = section.with_indifferent_access
        memo[section["id"].to_s] = section
      end

      @slide_deck.slide_sequence.flat_map do |section_id|
        section = sections_by_id[section_id.to_s]
        next [] unless section

        pages = Slides::Paginator.call(Array(section["lines"]))

        pages.map { |page_lines| { "type" => section["type"].to_s, "lines" => page_lines } }
      end
    end
  end
end

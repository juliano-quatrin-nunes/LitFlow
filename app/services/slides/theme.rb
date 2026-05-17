module Slides
  module Theme
    VERSION = "v1"

    module V1
      ASPECT = [ 10.0, 7.5 ].freeze
      BG_COLOR = "#000000"
      TEXT_COLOR = "#FFFFFF"
      FONT_FAMILY = "Calibri"
      FONT_SIZE = 42
      H_ALIGN = :center
      V_ALIGN = :middle
      MARGINS = 0.05
      MAX_CHARS_PER_LINE = 32
      MAX_VISUAL_LINES = 10
      BOLD_SECTION_TYPES = [ "chorus" ].freeze

      def self.to_h
        {
          "aspect" => ASPECT,
          "bg" => BG_COLOR,
          "text" => TEXT_COLOR,
          "font" => FONT_FAMILY,
          "size" => FONT_SIZE,
          "h_align" => H_ALIGN.to_s,
          "v_align" => V_ALIGN.to_s,
          "margins" => MARGINS,
          "bold_section_types" => BOLD_SECTION_TYPES
        }
      end
    end
  end
end

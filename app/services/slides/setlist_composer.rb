module Slides
  class SetlistComposer
    BLANK_SLIDE = { "type" => "blank", "lines" => [] }.freeze

    def self.call(setlist)
      new(setlist).call
    end

    def initialize(setlist)
      @setlist = setlist
    end

    def call
      deck = [ blank_slide ]
      ordered_items.each do |item|
        deck.concat(physical_slides_for(item))
        deck << blank_slide
      end
      deck
    end

    private

    def ordered_items
      @setlist.items.includes(:item).order(:position)
    end

    def blank_slide
      BLANK_SLIDE.dup
    end

    def physical_slides_for(setlist_item)
      sections_by_id = setlist_item.effective_slides_json.each_with_object({}) do |section, memo|
        section = section.with_indifferent_access
        memo[section["id"].to_s] = section
      end

      setlist_item.effective_slide_sequence.flat_map do |section_id|
        section = sections_by_id[section_id.to_s]
        next [] unless section

        pages = Slides::Paginator.call(Array(section["lines"]))

        pages.map { |page_lines| { "type" => section["type"].to_s, "lines" => page_lines } }
      end
    end
  end
end

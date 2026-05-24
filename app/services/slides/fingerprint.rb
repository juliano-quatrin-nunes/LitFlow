require "digest/sha1"

module Slides
  class Fingerprint
    def self.call(slides_json, slide_sequence, theme_version)
      payload = {
        "slides_json" => canonicalize(slides_json),
        "slide_sequence" => canonicalize(slide_sequence),
        "theme_version" => theme_version.to_s
      }
      Digest::SHA1.hexdigest(JSON.generate(payload))
    end

    def self.for_setlist(setlist)
      items_payload = setlist.items.includes(:item).order(:position).map do |item|
        {
          "item_type" => item.item_type,
          "item_id" => item.item_id,
          "position" => item.position,
          "mass_part_id" => item.mass_part_id,
          "slides_json" => canonicalize(item.effective_slides_json),
          "slide_sequence" => canonicalize(item.effective_slide_sequence)
        }
      end
      payload = {
        "items" => items_payload,
        "theme_version" => Slides::Theme::VERSION.to_s
      }
      Digest::SHA1.hexdigest(JSON.generate(payload))
    end

    def self.canonicalize(value)
      case value
      when Hash
        value.each_with_object({}) { |(k, v), memo| memo[k.to_s] = canonicalize(v) }
            .sort.to_h
      when Array
        value.map { |v| canonicalize(v) }
      else
        value
      end
    end
  end
end

module Slideable
  extend ActiveSupport::Concern

  included do
    has_one :slide_deck, as: :slideable, dependent: :destroy

    after_create_commit :seed_slide_deck
  end

  def seed_slide_deck
    deck = build_slide_deck

    if content_raw.present?
      slides = Slides::Extractor.call(content_json)
      deck.slides_json = slides
      deck.slide_sequence = Slides::Extractor.default_sequence(slides)
      deck.slides_generated_from = Digest::SHA1.hexdigest(content_raw)
    end

    deck.save!
  end
end

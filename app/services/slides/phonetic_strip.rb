module Slides
  class PhoneticStrip
    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @text = text.to_s
    end

    def call
      @text
        .gsub(/(\p{L})\1{2,}/i, '\1')
        .gsub(/\s+/, " ")
        .strip
    end
  end
end

module Slides
  class Paginator
    DEFAULT_MAX_VISUAL = 10
    DEFAULT_CHAR_THRESHOLD = 32

    def self.call(lines, max_visual: DEFAULT_MAX_VISUAL, char_threshold: DEFAULT_CHAR_THRESHOLD)
      new(lines, max_visual: max_visual, char_threshold: char_threshold).call
    end

    def initialize(lines, max_visual:, char_threshold:)
      @lines = Array(lines)
      @max_visual = max_visual
      @char_threshold = char_threshold
    end

    def call
      return [ [] ] if @lines.empty?

      pages, current, used = [], [], 0
      @lines.each do |line|
        cost = line.to_s.length > @char_threshold ? 2 : 1
        if used + cost > @max_visual
          pages << current
          current = [ line ]
          used = cost
        else
          current << line
          used += cost
        end
      end
      pages << current if current.any?
      pages
    end
  end
end

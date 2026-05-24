module Slides
  class Paginator
    def self.call(lines, max_visual: Slides::Theme::V1::MAX_VISUAL_LINES, max_chars: Slides::Theme::V1::MAX_CHARS_PER_LINE)
      new(lines, max_visual: max_visual, max_chars: max_chars).call
    end

    def initialize(lines, max_visual:, max_chars:)
      @lines = Array(lines)
      @max_visual = max_visual
      @max_chars = max_chars
    end

    def call
      return [ [] ] if @lines.empty?

      costs = @lines.map { |line| visual_lines_for(line) }
      total = costs.sum

      return [ @lines.dup ] if total <= @max_visual

      pages_count = (total.to_f / @max_visual).ceil
      target = (total.to_f / pages_count).ceil

      pages = []
      current = []
      used = 0

      @lines.zip(costs).each do |line, cost|
        if current.any? && used + cost > target && pages.size + 1 < pages_count
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

    private

    # Count visual lines produced by greedy word-wrap with strict-fit:
    # a visual line accommodates words as long as the running length stays
    # strictly less than @max_chars (so a line of exactly @max_chars chars
    # is treated as overflowing, matching how the renderer wraps).
    # Words longer than @max_chars are split mid-word at ceil(length/@max_chars).
    def visual_lines_for(line)
      text = line.to_s
      return 1 if text.strip.empty?

      lines_count = 0
      current_length = 0
      text.split(/\s+/).reject(&:empty?).each do |word|
        if word.length >= @max_chars
          lines_count += 1 if current_length > 0
          lines_count += (word.length.to_f / @max_chars).ceil
          current_length = 0
        elsif current_length.zero?
          current_length = word.length
        else
          tentative = current_length + 1 + word.length
          if tentative < @max_chars
            current_length = tentative
          else
            lines_count += 1
            current_length = word.length
          end
        end
      end
      lines_count += 1 if current_length > 0
      [ lines_count, 1 ].max
    end
  end
end

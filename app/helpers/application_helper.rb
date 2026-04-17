module ApplicationHelper
  def cn(*args)
    @tailwind_merger ||= TailwindMerge::Merger.new
    @tailwind_merger.merge(class_names(*args))
  end
end

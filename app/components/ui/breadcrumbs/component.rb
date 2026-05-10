class Ui::Breadcrumbs::Component < ApplicationComponent
  def initialize(separator: "/", **options)
    @separator = separator
    @options = options
  end

  def call
    content_tag :nav, class: classes, aria: { label: "Breadcrumb" }, **@options.except(:class) do
      # Render children and interleave with separators
      items = content.to_s.scan(/<span.*?<\/span>|<a.*?<\/a>/m).reject(&:blank?)
      
      safe_join(items.each_with_index.map do |item, index|
        if index < items.size - 1
          safe_join([
            item.html_safe,
            content_tag(:span, @separator, class: "mx-2 text-muted-foreground/50 font-normal")
          ])
        else
          item.html_safe
        end
      end)
    end
  end

  private

  def classes
    class_names(
      "breadcrumbs flex items-center flex-wrap",
      @options[:class]
    )
  end
end

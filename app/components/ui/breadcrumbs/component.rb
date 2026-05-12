class Ui::Breadcrumbs::Component < ApplicationComponent
  def initialize(separator: "/", **options)
    @separator = separator
    @options = options
  end

  def call
    content_tag :nav, class: classes, aria: { label: "Breadcrumb" }, **@options.except(:class) do
      doc = Nokogiri::HTML::DocumentFragment.parse(content.to_s)

      elements = doc.children.select(&:element?)

      elements[0...-1].each do |element|
        separator_html = content_tag(:span, @separator, class: "mx-2 text-muted-foreground/50 font-normal")
        element.add_next_sibling(separator_html)
      end

      doc.to_html.html_safe
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

class Ui::Breadcrumb::Component < ApplicationComponent
  def initialize(url: nil, active: false, **options)
    @url = url
    @active = active
    @options = options
  end

  def call
    if @url && !@active
      link_to content, @url, class: classes, **@options.except(:class)
    else
      content_tag :span, content, class: classes, **@options.except(:class)
    end
  end

  private

  def classes
    class_names(
      "breadcrumbs__item",
      { "breadcrumbs__item--active": @active },
      @options[:class]
    )
  end
end

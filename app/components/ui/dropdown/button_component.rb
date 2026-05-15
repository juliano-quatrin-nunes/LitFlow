class Ui::Dropdown::ButtonComponent < ApplicationComponent
  def initialize(url: nil, active: false, **options)
    @url = url
    @active = active
    @options = options
  end

  erb_template <<~ERB
    <li class="dropdown__item">
      <%= button_to content, @url, class: classes, **@options %>
    </li>
  ERB

  private

  def classes
    class_names(
      "dropdown__link w-full text-left",
      ("dropdown__link-active" if @active),
      @options.delete(:class)
    )
  end
end

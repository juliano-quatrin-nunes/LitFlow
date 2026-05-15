class Ui::Dropdown::SubContentComponent < ApplicationComponent
  def initialize(**options)
    super
    @options = options
  end

  erb_template <<~ERB
    <%= content_tag :ul, class: classes, **attrs do %>
      <%= content %>
    <% end %>
  ERB

  private

  def attrs
    data_attributes = { 
      dropdown_target: "menu"
    }.deep_merge(@options.fetch(:data, {}))

    @options.merge(data: data_attributes)
  end

  def classes
    class_names(
      "dropdown__menu",
      @options.delete(:class)
    )
  end
end

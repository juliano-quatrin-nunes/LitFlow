class Ui::Dropdown::SubComponent < ApplicationComponent
  def initialize(**options)
    super
    @options = options
  end

  erb_template <<~ERB
    <%= content_tag :div, class: classes, **attrs do %>
      <%= content %>
    <% end %>
  ERB

  private

  def attrs
    data_attributes = {
      controller: "dropdown",
      dropdown_placement_value: @options.delete(:placement) || "right-start",
      dropdown_trigger_value: @options.delete(:trigger) || "hover"
    }.deep_merge(@options.fetch(:data, {}))

    @options.merge(data: data_attributes)
  end

  def classes
    class_names(
      "dropdown dropdown-sub w-full",
      @options.delete(:class)
    )
  end
end

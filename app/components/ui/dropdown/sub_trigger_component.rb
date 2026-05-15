class Ui::Dropdown::SubTriggerComponent < ApplicationComponent
  def initialize(label = nil, **options)
    super(**options)
    @label = label
    @options = options
  end

  erb_template <<~ERB
    <li class="dropdown__item">
      <%= content_tag :div, class: classes, **attrs do %>
        <%= @label || content %>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-chevron-right ml-1 opacity-50"><path d="m9 18 6-6-6-6"/></svg>
      <% end %>
    </li>
  ERB

  private

  def attrs
    data_attributes = { 
      dropdown_target: "autofocus",
      action: "click->dropdown#toggle"
    }.deep_merge(@options.fetch(:data, {}))

    @options.merge(data: data_attributes, type: @options[:type] || "button")
  end

  def classes
    class_names(
      "dropdown__link flex items-center justify-between w-full select-none cursor-default",
      @options.delete(:class)
    )
  end
end

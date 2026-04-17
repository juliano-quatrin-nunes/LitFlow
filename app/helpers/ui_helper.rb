module UiHelper
  def ui
    @ui_builder ||= UiBuilder.new(self)
  end

  class UiBuilder
    def initialize(view_context)
      @view = view_context
    end

    def method_missing(name, *args, **kwargs, &block)
      component_class = resolve_component(name)
      # If the first argument is not a hash, treat it as content
      content = args.shift unless args.first.is_a?(Hash) || args.empty?
      instance = component_class.new(*args, **kwargs)

      if block
        @view.render(instance, &block)
      elsif content
        @view.render(instance) { content.to_s }
      else
        @view.render(instance)
      end
    end

    private

    def resolve_component(name)
      # Try Ui::Btn::Component first, then fallback to other patterns
      camel_name = name.to_s.camelize
      class_names = [
        "Ui::#{camel_name}::Component",
        "::Ui::#{camel_name}::Component"
      ]

      # Add underscore-based fallbacks (e.g. turbo_confirm -> Ui::TurboConfirm::Component)
      if name.to_s.include?("_")
        parts = name.to_s.split("_")
        class_names << "Ui::#{parts.first.camelize}::#{parts.drop(1).map(&:camelize).join}Component"
        class_names << "::Ui::#{parts.first.camelize}::#{parts.drop(1).map(&:camelize).join}Component"
      end

      class_names.each do |class_name|
        component = class_name.safe_constantize
        return component if component
      end

      raise NameError, "Could not find component for '#{name}'. Tried: #{class_names.join(', ')}"
    end
  end
end

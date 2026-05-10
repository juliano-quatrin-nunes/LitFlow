class ApplicationComponent < ViewComponent::Base
  include Turbo::FramesHelper
  delegate :cn, to: :helpers

  def initialize(**options)
    @options = options
  end
end

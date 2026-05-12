module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      unless authenticated? && Current.user.admin?
        redirect_to root_path, alert: "Acesso restrito a administradores."
      end
    end
  end
end
module Admin
  class InvitationsController < BaseController
    def index
      @invitations = Invitation.order(created_at: :desc)
      @invitation = Invitation.new
    end

    def create
      @invitation = Invitation.new
      if @invitation.save
        redirect_to admin_invitations_path, notice: "Convite gerado com sucesso!"
      else
        @invitations = Invitation.order(created_at: :desc)
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      @invitation = Invitation.find(params[:id])
      @invitation.destroy
      redirect_to admin_invitations_path, notice: "Convite excluído."
    end

  end
end

class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_if_authenticated
  before_action :set_invitation, only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :user # Default role for invited users

    if @user.save
      @invitation.destroy
      start_new_session_for @user
      redirect_to root_path, notice: "Bem-vindo ao Litflow! Sua conta foi criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_authenticated
    redirect_to root_path, alert: "Você já está logado." if authenticated?
  end

  def set_invitation
    @invitation = Invitation.find_by!(token: params[:token])
    if @invitation.expired?
      redirect_to new_session_path, alert: "Este link de convite expirou."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to new_session_path, alert: "Link de convite inválido."
  end

  def user_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end
end

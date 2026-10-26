class RegistrationsController < ApplicationController
  skip_before_action :require_authentication
  before_action :require_self_registration_enabled

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :organizer

    if @user.save
      sign_in(@user)
      redirect_to conferences_path, notice: t("app.flash.account_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_self_registration_enabled
    return if self_registration_enabled?

    redirect_to new_session_path, alert: t("app.flash.registration_disabled")
  end

  def user_params
    params.require(:user).permit(:email_address, :name, :password, :password_confirmation)
  end
end

class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [ :new, :create ]
  before_action :set_conference, only: [ :index, :show ]
  before_action :authorize_organizer, only: [ :index, :show ]
  before_action :set_public_session, only: :show

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_to conferences_path, notice: t("app.flash.logged_in")
    else
      flash.now[:alert] = t("app.flash.invalid_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: t("app.flash.logged_out")
  end

  def index
    @sessions = @conference.sessions.chronological
  end

  def show
  end

  private

  def set_conference
    @conference = Conference.find_by!(slug: params[:conference_slug])
  end

  def set_public_session
    @session = @conference.sessions.find_by!(slug: params[:id])
  end

  def authorize_organizer
    return if organizer_for?(@conference)

    redirect_to root_path, alert: t("app.flash.forbidden")
  end
end

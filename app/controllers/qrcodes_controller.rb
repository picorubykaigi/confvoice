class QrcodesController < ApplicationController
  before_action :set_conference
  before_action :authorize_organizer

  def index
    @sessions = @conference.sessions.chronological
  end

  private

  def set_conference
    @conference = Conference.find_by!(slug: params[:conference_slug])
  end

  def authorize_organizer
    return if organizer_for?(@conference)

    redirect_to root_path, alert: t("app.flash.forbidden")
  end
end

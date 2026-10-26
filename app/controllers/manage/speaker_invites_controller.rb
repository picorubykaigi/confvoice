class Manage::SpeakerInvitesController < ApplicationController
  before_action :set_conference
  before_action :authorize_organizer
  before_action :set_session

  def create
    revoke_active_invites
    @session.speaker_invites.create!

    redirect_to conference_manage_session_path(@conference, @session), notice: t("app.flash.invite_created")
  end

  def destroy
    revoke_active_invites
    redirect_to conference_manage_session_path(@conference, @session), notice: t("app.flash.invite_revoked")
  end

  private

  def set_conference
    @conference = Conference.find_by!(slug: params[:conference_slug])
  end

  def set_session
    @session = @conference.sessions.find_by!(slug: params[:session_id])
  end

  def authorize_organizer
    return if organizer_for?(@conference)

    redirect_to root_path, alert: t("app.flash.forbidden")
  end

  def revoke_active_invites
    now = Time.current
    @session.speaker_invites.active.update_all(revoked_at: now, updated_at: now)
  end
end

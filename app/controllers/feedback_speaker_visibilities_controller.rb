class FeedbackSpeakerVisibilitiesController < ApplicationController
  before_action :set_conference
  before_action :authorize_organizer
  before_action :set_session
  before_action :set_feedback

  def update
    @feedback.share_with_speaker!
    redirect_to conference_session_feedbacks_path(@conference, @session), notice: t("app.flash.feedback_shared")
  end

  def destroy
    @feedback.hide_from_speaker!
    redirect_to conference_session_feedbacks_path(@conference, @session), notice: t("app.flash.feedback_unshared")
  end

  private

  def set_conference
    @conference = Conference.find_by!(slug: params[:conference_slug])
  end

  def set_session
    @session = @conference.sessions.find_by!(slug: params[:session_id])
  end

  def set_feedback
    @feedback = @session.feedbacks.find(params[:feedback_id])
  end

  def authorize_organizer
    return if organizer_for?(@conference)

    redirect_to root_path, alert: t("app.flash.forbidden")
  end
end

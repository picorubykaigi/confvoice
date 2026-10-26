class FeedbackMailer < ApplicationMailer
  def speaker_notification
    @feedback = params[:feedback]
    @session = @feedback.session
    @conference = @session.conference

    mail(
      to: @session.speaker_user.email_address,
      subject: I18n.t("feedback_mailer.speaker_notification.subject", session: @session.title)
    )
  end
end

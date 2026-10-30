module PublicSessionScoping
  extend ActiveSupport::Concern

  private

  def set_session
    @session = Session.joins(:conference).merge(Conference.published).find(params[:id])
    @conference = @session.conference
  end
end

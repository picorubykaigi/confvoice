class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :use_default_locale
  before_action :require_authentication

  helper_method :current_user, :authenticated?, :organizer_for?, :member_of?, :self_registration_enabled?, :ogp_image_upload_enabled?

  private

  def use_default_locale(&action)
    I18n.with_locale(I18n.default_locale, &action)
  end

  def require_authentication
    return if authenticated?

    redirect_to new_session_path, alert: t("app.flash.login_required")
  end

  def authenticated?
    current_user.present?
  end

  def current_user
    Current.user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def sign_in(user)
    reset_session
    session[:user_id] = user.id
    Current.user = user
  end

  def sign_out
    reset_session
    Current.user = nil
  end

  def require_admin
    return if current_user&.admin?

    redirect_to root_path, alert: t("app.flash.forbidden")
  end

  def organizer_for?(conference)
    current_user&.admin? || conference.conference_memberships.exists?(user: current_user, role: :organizer)
  end

  def member_of?(conference)
    current_user&.admin? || conference.conference_memberships.exists?(user: current_user)
  end

  def self_registration_enabled?
    default = Rails.env.production? ? "false" : "true"

    ActiveModel::Type::Boolean.new.cast(ENV.fetch("CONFVOICE_SELF_REGISTRATION_ENABLED", default))
  end

  def ogp_image_upload_enabled?
    default = Rails.env.production? ? "false" : "true"

    ActiveModel::Type::Boolean.new.cast(ENV.fetch("CONFVOICE_OGP_IMAGE_UPLOAD_ENABLED", default))
  end
end

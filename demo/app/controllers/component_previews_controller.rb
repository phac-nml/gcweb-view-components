# Renders component previews (for Lookbook and /rails/view_components) in the
# requested language, under the app's strict Content-Security-Policy.
#
# Locale comes from Lookbook's "lang" display option, or from ?locale=fr when
# a preview URL is opened directly (used by the a11y and visual checks).
class ComponentPreviewsController < ViewComponentsController
  # Rails' preview controller relaxes CSP and drops the nonce, and
  # ViewComponent's preview actions turn CSP off entirely. Put the app policy
  # back so previews prove components work under the same strict CSP host apps
  # run (e.g. no inline style="" attributes). Runs after the inherited filters.
  skip_before_action :disable_content_security_policy_nonce!
  before_action { request.content_security_policy = Rails.application.config.content_security_policy }

  around_action :with_preview_locale

  private

  def with_preview_locale(&)
    I18n.with_locale(preview_locale, &)
  end

  def preview_locale
    requested = params.dig(:lookbook, :display, :lang) || params[:locale]
    locale = requested.to_s.to_sym
    I18n.available_locales.include?(locale) ? locale : I18n.default_locale
  end
end

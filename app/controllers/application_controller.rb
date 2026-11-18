class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  private

  def set_locale
    I18n.locale = extracted_locale || I18n.default_locale
  end

  def extracted_locale
    locale = params[:locale]&.to_sym
    locale if I18n.available_locales.include?(locale)
  end

  def default_url_options
    locale = I18n.locale == I18n.default_locale ? nil : I18n.locale
    { locale: locale }
  end
end

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale

  # Every path/url helper carries the current locale forward, so links and
  # form submissions stay on the same language without passing it explicitly.
  # The default locale is left off the URL entirely, so "/" still works.
  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  private
    def switch_locale(&action)
      I18n.with_locale(locale_from_params || I18n.default_locale, &action)
    end

    def locale_from_params
      params[:locale] if I18n.available_locales.map(&:to_s).include?(params[:locale])
    end
end

module AppShell
  class LanguageSwitchComponent < ViewComponent::Base
    def links
      [
        { locale: :en, label: I18n.t("app.language_switch.english") },
        { locale: :fr, label: I18n.t("app.language_switch.french") }
      ]
    end

    def language_href(locale)
      helpers.url_for(locale: locale)
    end
  end
end

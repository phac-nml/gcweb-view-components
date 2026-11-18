module AppShell
  class SkipLinksComponent < ViewComponent::Base
    def links
      [
        { href: "#main-content", label: I18n.t("app.shell.skip_to_main") },
        { href: "#site-footer", label: I18n.t("app.shell.skip_to_footer") }
      ]
    end
  end
end

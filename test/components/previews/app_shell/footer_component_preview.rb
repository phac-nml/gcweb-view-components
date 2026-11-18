module AppShell
  class FooterComponentPreview < ViewComponent::Preview
    def en
      I18n.with_locale(:en) { render(AppShell::FooterComponent.new) }
    end

    def fr
      I18n.with_locale(:fr) { render(AppShell::FooterComponent.new) }
    end
  end
end

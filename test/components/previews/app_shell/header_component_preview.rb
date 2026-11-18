module AppShell
  class HeaderComponentPreview < ViewComponent::Preview
    def en
      I18n.with_locale(:en) { render(AppShell::HeaderComponent.new) }
    end

    def fr
      I18n.with_locale(:fr) { render(AppShell::HeaderComponent.new) }
    end
  end
end

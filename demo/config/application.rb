require_relative "boot"

require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

require "gcweb_view_components"

module Demo
  # Lookbook host for the gcweb_view_components gem. Not deployed.
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.default_locale = :en
    config.i18n.available_locales = %i[en fr]
    config.i18n.fallbacks = true

    # Previews and their templates live in the gem (test/components/previews).
    # Both settings are needed: ViewComponent uses previews.paths for
    # render_with_template lookups; Lookbook uses preview_paths for discovery.
    previews_path = GcwebViewComponents.root.join("test/components/previews").to_s
    config.view_component.previews.paths = [ previews_path ]
    config.view_component.previews.default_layout = "component_preview"
    config.view_component.previews.controller = "ComponentPreviewsController"

    if config.respond_to?(:lookbook)
      config.lookbook.preview_paths = [ previews_path ]
      config.lookbook.preview_controller = "ComponentPreviewsController"
      config.lookbook.project_name = "GCWeb View Components"
      # Language toggle in the Lookbook toolbar (read by ComponentPreviewsController).
      config.lookbook.preview_display_options = {
        lang: [ [ "English", "en" ], [ "Français", "fr" ] ]
      }
    end
  end
end

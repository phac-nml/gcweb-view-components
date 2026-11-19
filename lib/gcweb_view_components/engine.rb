require "rails/engine"

module GcwebViewComponents
  class Engine < ::Rails::Engine
    # Components live under the top-level `Gcweb::` namespace
    # (app/components/gcweb/*), so the engine is not isolated. Rails adds the
    # engine's app/components to the host's autoload paths, and config/locales
    # to the I18n load path, automatically.

    # Propshaft / Sprockets hosts: serve the prebuilt CSS and its fonts only.
    # The SCSS sources and the JS sources are for bundler-based hosts (Vite,
    # esbuild) that import them from the gem path.
    initializer "gcweb_view_components.assets" do |app|
      next unless app.config.respond_to?(:assets)

      if app.config.assets.respond_to?(:excluded_paths)
        app.config.assets.excluded_paths << root.join("app/assets/javascripts").to_s
      end
    end
  end
end

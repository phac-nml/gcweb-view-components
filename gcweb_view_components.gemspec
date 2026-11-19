require_relative "lib/gcweb_view_components/version"

Gem::Specification.new do |spec|
  spec.name = "gcweb_view_components"
  spec.version = GcwebViewComponents::VERSION
  spec.authors = [ "Bioinformatics, Public Health Agency of Canada" ]
  spec.summary = "GCWeb (WET-BOEW) components for Rails, built with ViewComponent and Stimulus"
  spec.description = <<~DESC
    ViewComponents that render GCWeb / WET-BOEW markup and look like Canada.ca,
    with hand-written SCSS (no jQuery, no wet-boew.js) and Stimulus controllers
    for interactive behaviour.
  DESC
  spec.homepage = "https://github.com/phac-nml/gcweb-view-components"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"
  # GCWeb release whose markup and computed styles these components target.
  spec.metadata["gcweb_version"] = GcwebViewComponents::GCWEB_VERSION

  spec.files = Dir[
    "app/components/**/*",
    "app/form_builders/**/*",
    "app/assets/javascripts/**/*",
    "app/assets/stylesheets/**/*",
    "config/locales/**/*",
    "lib/**/*",
    "package.json",
    "README.md",
    "LICENSE"
  ]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "actionview", ">= 8.0"
  spec.add_dependency "activesupport", ">= 8.0"
  spec.add_dependency "railties", ">= 8.0"
  spec.add_dependency "view_component", ">= 4.0", "< 5.0"
end

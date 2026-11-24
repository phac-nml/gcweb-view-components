source "https://rubygems.org"

# The gem itself (runtime dependencies come from the gemspec).
gemspec

# Demo / Lookbook host app (demo/) and test tooling.
gem "rails", "~> 8.1.4", ">= 8.1.4.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "vite_rails", ">= 3.11"
# Optional for apps: paged data tables take a Pagy object.
gem "pagy", "~> 43.6"
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "lookbook", ">= 2.3"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "capybara"
end

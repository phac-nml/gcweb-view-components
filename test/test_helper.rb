ENV["RAILS_ENV"] ||= "test"

require_relative "../demo/config/environment"
require "rails/test_help"
require "view_component/test_helpers"
require "capybara/minitest"

# Build the demo's Vite assets once, before parallel workers fork; otherwise
# each worker's first preview request would start its own build.
ViteRuby.commands.build || abort("Vite build failed; run `cd demo && bin/vite build --mode test`")

# In the test environment Rails writes a random secret to
# demo/tmp/local_secret.txt the first time it's needed. On a fresh checkout
# (CI) parallel workers race to create it and one can read it half-written
# (""), failing with "secret_key_base ... got: \"\"". Create it here first.
Rails.application.secret_key_base

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
  end
end

class ComponentTestCase < ViewComponent::TestCase
  include Capybara::Minitest::Assertions
end

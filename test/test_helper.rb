ENV["RAILS_ENV"] ||= "test"

require_relative "../demo/config/environment"
require "rails/test_help"
require "view_component/test_helpers"
require "capybara/minitest"

# Build the demo's Vite assets once, before parallel workers fork; otherwise
# each worker's first preview request would start its own build.
ViteRuby.commands.build || abort("Vite build failed; run `cd demo && bin/vite build --mode test`")

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
  end
end

class ComponentTestCase < ViewComponent::TestCase
  include Capybara::Minitest::Assertions
end

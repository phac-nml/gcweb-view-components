require "view_component"
require "gcweb_view_components/version"
require "gcweb_view_components/form_helper"
require "gcweb_view_components/toggle_helper"
require "gcweb_view_components/overlay_helper"
require "gcweb_view_components/engine"

module GcwebViewComponents
  def self.root
    Pathname(File.expand_path("..", __dir__))
  end
end

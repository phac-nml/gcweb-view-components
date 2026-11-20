require "test_helper"

class ToggleHelperTest < ActiveSupport::TestCase
  include GcwebViewComponents::ToggleHelper

  test "builds GCWeb's data-toggle JSON for the gcweb--toggle controller" do
    data = gcweb_toggle_data(selector: "details", parent: "#faq", type: :on, print: :on)

    assert_equal "gcweb--toggle", data[:controller]
    assert_equal({ "selector" => "details", "parent" => "#faq", "type" => "on", "print" => "on" }, JSON.parse(data[:toggle]))
  end

  test "maps state classes to wet-boew's names and leaves out unset options" do
    data = gcweb_toggle_data(state_on: "shown", state_off: "hidden")

    assert_equal({ "stateOn" => "shown", "stateOff" => "hidden" }, JSON.parse(data[:toggle]))
  end

  test "keeps other data attributes and joins controllers" do
    data = gcweb_toggle_data(selector: ".box", data: { controller: "tracking", testid: "toggle" })

    assert_equal "tracking gcweb--toggle", data[:controller]
    assert_equal "toggle", data[:testid]
  end

  test "rejects unknown options" do
    assert_raises(ArgumentError) { gcweb_toggle_data(selectr: "details") }
  end
end

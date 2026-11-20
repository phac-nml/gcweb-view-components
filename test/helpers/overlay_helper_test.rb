require "test_helper"

class OverlayHelperTest < ActionView::TestCase
  include GcwebViewComponents::OverlayHelper

  test "renders GCWeb's overlay-lnk link" do
    html = Nokogiri::HTML5.fragment(gcweb_overlay_link_to("Left panel", "left-panel", class: "btn btn-default", data: { x: 1 }))
    link = html.at_css("a")

    assert_equal "#left-panel", link["href"]
    assert_equal "left-panel", link["aria-controls"]
    assert_equal "button", link["role"]
    assert_equal "overlay-lnk btn btn-default", link["class"]
    assert_equal "1", link["data-x"]
    assert_equal "Left panel", link.text
  end

  test "takes the text from a block" do
    html = Nokogiri::HTML5.fragment(gcweb_overlay_link_to("left-panel") { "Open <b>it</b>".html_safe })

    assert_equal "#left-panel", html.at_css("a")["href"]
    assert_equal "it", html.at_css("a > b").text
  end

  test "needs an overlay id" do
    assert_raises(ArgumentError) { gcweb_overlay_link_to("Left panel") }
  end
end

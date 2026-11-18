require "test_helper"

class ShellLayoutTest < ActionDispatch::IntegrationTest
  test "renders global shell in english" do
    get root_path

    assert_response :success
    assert_select "nav.skip-links a[href='#main-content']", "Skip to main content"
    assert_select "header.site-header", count: 1
    assert_select "nav.language-switch a[lang='en']", "English"
    assert_select "main#main-content[tabindex='-1']", count: 1
    assert_select "footer#site-footer.site-footer", count: 1
  end

  test "renders global shell in french" do
    get root_path(locale: :fr)

    assert_response :success
    assert_select "nav.skip-links a[href='#main-content']", "Passer au contenu principal"
    assert_select "header.site-header p.site-header__signature", "Gouvernement du Canada"
    assert_select "nav.language-switch a[lang='fr'][aria-current='true']", "Français"
    assert_select "footer#site-footer.site-footer", count: 1
  end
end

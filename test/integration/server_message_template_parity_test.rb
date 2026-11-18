require "test_helper"

class ServerMessageTemplateParityTest < ActionDispatch::IntegrationTest
  test "renders english server message template sections" do
    get server_message_page_path

    assert_response :success
    assert_select "h1", "Message title - Canada.ca theme"
    assert_select "span.server-message-page__code", "Error code"
    assert_select "section.server-message-page p", /Sample text/
  end

  test "renders french server message template sections" do
    get server_message_page_path(locale: :fr)

    assert_response :success
    assert_select "h1", "Titre du message - Thème Canada.ca"
    assert_select "span.server-message-page__code", "Code d'erreur"
    assert_select "section.server-message-page p", /Texte d'exemple/
  end
end

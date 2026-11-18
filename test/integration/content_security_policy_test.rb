require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "enforces strict csp header on health endpoint" do
    get rails_health_check_path

    assert_response :success

    header = response.headers["Content-Security-Policy"]
    assert_not_nil header
    assert_includes header, "default-src 'self' https:"
    assert_includes header, "object-src 'none'"
    refute_includes header, "'unsafe-inline'"
    refute_includes header, "'unsafe-eval'"
  end
end

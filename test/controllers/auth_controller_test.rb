require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "should get auth_user" do
    get auth_auth_user_url
    assert_response :success
  end
end

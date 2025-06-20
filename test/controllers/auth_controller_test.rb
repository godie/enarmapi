require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  fixtures :users # Ensure users fixtures are loaded

  test "should get auth_user" do
    admin = users(:admin) # Get admin user from fixtures
    # Route is 'post "auth_user", to: "auth#auth_user"'
    post auth_user_url, params: { email: admin.email, password: "password" }, as: :json
    assert_response :success
  end
end

require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  fixtures :users # Ensure users fixtures are loaded

  test "should get auth_user" do
    admin = users(:admin) # Get admin user from fixtures
    # Using the users#login route which should handle authentication
    post login_users_url, params: { email: admin.email, password: "password" }, as: :json
    assert_response :success
  end
end

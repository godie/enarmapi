require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  fixtures :users # Load user fixtures

  setup do
    @admin_user = users(:admin) # Assumes a fixture named 'admin' in users.yml
    @auth_headers = admin_auth_headers(@admin_user)

    # Default attributes for creating/updating users
    @valid_user_attrs = {
      username: "newuser",
      email: "newuser@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
    @invalid_user_attrs = {
      username: "nouser",
      email: "", # Invalid: email is blank
      password: "password123",
      password_confirmation: "password123"
    }
  end

  # --- Authentication Tests ---
  test "should get unauthorized on index without token" do
    get users_url, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on show without token" do
    get user_url(@admin_user), as: :json # Using admin_user for an existing ID
    assert_response :unauthorized
  end

  test "should get created on create without token" do
    post users_url, params: { user: @valid_user_attrs }, as: :json
    assert_response :created
  end

  test "should get unauthorized on update without token" do
    put user_url(@admin_user), params: { user: @valid_user_attrs }, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on destroy without token" do
    delete user_url(@admin_user), as: :json
    assert_response :unauthorized
  end

  # --- CRUD Tests (as Admin) ---
  test "should get index when authenticated" do
    get users_url, headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_not_empty response_json, "Response should not be empty"
    # Add more assertions if needed, e.g., checking for specific user fields
  end

  test "should create user when authenticated" do
    assert_difference("User.count") do
      post users_url, params: { user: @valid_user_attrs }, headers: @auth_headers, as: :json
    end
    assert_response :created
    response_json = JSON.parse(response.body)
    assert_equal @valid_user_attrs[:email], response_json["email"]
    assert_equal @valid_user_attrs[:username], response_json["username"]
  end

  test "should show user when authenticated" do
    # Create a user to show, or use an existing one if not admin
    user_to_show = User.create!(username: "showme", email: "showme@example.com", password: "password")
    get user_url(user_to_show), headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_equal user_to_show.email, response_json["email"]
  end

  test "should update user when authenticated" do
    user_to_update = User.create!(username: "updateme", email: "updateme@example.com", password: "password")
    updated_username = "updated_username"
    put user_url(user_to_update), params: { user: { username: updated_username } }, headers: @auth_headers, as: :json
    assert_response :success
    user_to_update.reload
    assert_equal updated_username, user_to_update.username
  end

  test "should destroy user when authenticated" do
    user_to_destroy = User.create!(username: "deleteme", email: "deleteme@example.com", password: "password")
    assert_difference("User.count", -1) do
      delete user_url(user_to_destroy), headers: @auth_headers, as: :json
    end
    assert_response :no_content
  end

  # --- Validation Tests ---
  test "should not create user with invalid data" do
    assert_no_difference("User.count") do
      post users_url, params: { user: @invalid_user_attrs }, headers: @auth_headers, as: :json
    end
    assert_response :unprocessable_entity
    # Optionally, check the error messages in the response body
    # response_json = JSON.parse(response.body)
    # assert_not_nil response_json["errors"]["email"]
  end

  test "should not update user with invalid data" do
    user_to_update = User.create!(username: "validupdate", email: "validupdate@example.com", password: "password")
    original_email = user_to_update.email
    put user_url(user_to_update), params: { user: { email: "" } }, headers: @auth_headers, as: :json # Invalid: blank email
    assert_response :unprocessable_entity
    user_to_update.reload
    assert_equal original_email, user_to_update.email # Ensure email was not changed
  end

  test "GET me/contributions returns current user contributions when authenticated" do
    get me_contributions_users_url, headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert response_json.key?("contributions"), "Response must include contributions"
    assert_kind_of Array, response_json["contributions"]
  end

  test "GET me/contributions returns unauthorized without token" do
    get me_contributions_users_url, as: :json
    assert_response :unauthorized
  end
end

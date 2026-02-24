require "test_helper"

class SpecialistsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  setup do
    @user = users(:user_one)
    @auth_headers = admin_auth_headers(@user)
    @specialist_user = User.create!(
      name: "Dr. Specialist",
      email: "specialist@example.com",
      username: "specialist_doc",
      password: "password",
      password_confirmation: "password",
      role: :specialist
    )
    @specialist_user.create_specialist_profile!(specialty: "Cardiología", is_verified: true, bio: "Expert")
  end

  test "should get index when authenticated" do
    get specialists_url, headers: @auth_headers, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  test "should get unauthorized on index without token" do
    get specialists_url, as: :json
    assert_response :unauthorized
  end

  test "should get show when authenticated" do
    get specialist_url(@specialist_user), headers: @auth_headers, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @specialist_user.id, json["id"]
    assert json["specialist_profile"].present?
    assert_equal "Cardiología", json["specialist_profile"]["specialty"]
  end

  test "should return not_found for show with invalid id" do
    get specialist_url(999999), headers: @auth_headers, as: :json
    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal "Specialist not found", json["error"]
  end
end

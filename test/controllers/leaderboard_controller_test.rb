require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :achievements, :user_achievements

  setup do
    @user = users(:admin)
    @auth_headers = admin_auth_headers(@user)
  end

  test "should get index" do
    get "/leaderboard", headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_kind_of Array, response_json
  end
end

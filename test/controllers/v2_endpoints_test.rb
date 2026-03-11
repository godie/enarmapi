require "test_helper"

class V2EndpointsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "test@example.com", password: "password123", username: "testuser")
    @category = Category.create!(name: "Test Category")
    @token = JsonWebToken.encode(user_id: @user.id)
    @headers = { "Authorization" => "Bearer #{@token}" }
  end

  test "should get national leaderboard" do
    get "/v2/leaderboard/national", headers: @headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "currentUser"
    assert_includes json.keys, "topPlayers"
  end

  test "should get image bank" do
    get "/v2/images/bank", headers: @headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "images"
    assert_includes json.keys, "pagination"
  end

  test "should get flashcards for review" do
    get "/v2/flashcards/review", headers: @headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "flashcards"
  end

  test "should get knowledge base" do
    get "/v2/knowledge-base", headers: @headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "topics"
  end

  test "should get errors summary" do
    get "/v2/errors/summary", headers: @headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "mostFailedSpecialties"
    assert_includes json.keys, "recentFailedQuestions"
  end
end

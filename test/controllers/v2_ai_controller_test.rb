require "test_helper"

class V2AiControllerTest < ActionDispatch::IntegrationTest
  fixtures :users
  setup do
    @admin = users(:admin)
    @user = users(:player_one)
  end

  test "should generate flashcards as admin" do
    GenerativeAiService.stubs(:generate_flashcards).returns([
      { "front" => "AI Front 1", "back" => "AI Back 1" },
      { "front" => "AI Front 2", "back" => "AI Back 2" }
    ])

    assert_difference("Flashcard.count", 2) do
      post "/v2/ai/generate-flashcards",
        params: { topic: "Diabetes", count: 2, difficulty: "fácil" },
        headers: admin_auth_headers(@admin)
    end
    assert_response :success

    data = json_response
    assert_equal 2, data.size
    assert_equal "waiting_approval", data.first["status"]
  end

  test "should fail to generate flashcards as regular user" do
    post "/v2/ai/generate-flashcards",
      params: { topic: "Diabetes" },
      headers: player_auth_headers(@user)
    assert_response :forbidden
  end
end

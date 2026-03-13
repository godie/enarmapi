require "test_helper"

class V2FlashcardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:player_one)
    @category = categories(:one)
  end

  test "should create flashcard" do
    assert_difference("Flashcard.count", 1) do
      assert_difference("UserFlashcard.count", 1) do
        post "/v2/flashcards",
          params: { front: "Front text", back: "Back text", specialtyId: @category.id, tags: "tag1, tag2" },
          headers: player_auth_headers(@user)
      end
    end
    assert_response :created

    flashcard = Flashcard.last
    assert_equal "Front text", flashcard.front
    assert_equal "published", flashcard.status
    assert_equal "tag1, tag2", flashcard.tags
    assert_equal @category.id, flashcard.category_id
  end

  test "should fail to create flashcard with invalid params" do
    post "/v2/flashcards",
      params: { front: "" },
      headers: player_auth_headers(@user)
    assert_response :unprocessable_entity
  end
end

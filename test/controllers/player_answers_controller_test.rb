require "test_helper"

class PlayerAnswersControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get player_answers_create_url
    assert_response :success
  end

  test "should get index" do
    get player_answers_index_url
    assert_response :success
  end
end

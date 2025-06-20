require "test_helper"

class PlayerAnswersControllerTest < ActionDispatch::IntegrationTest
  fixtures :players
   setup do
      @player_one = players(:player_one)
      @auth_headers = player_auth_headers(@player_one)
   end
  test "should get unauthorized on index without token" do
    get player_answers_url
    assert_response :unauthorized
  end
end

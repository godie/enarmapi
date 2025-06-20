require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  fixtures :players # Added fixture loading

  setup do
    @player = players(:player_one) # Corrected fixture label
  end

  test "should get index" do
    get players_url, as: :json
    assert_response :success
  end

  test "should create player" do
    new_player_attrs = {
      name: "New Player Name",
      email: "newplayer@example.com",
      facebook_id: "fb_new_player_unique_id_#{SecureRandom.hex(4)}" # Ensure unique facebook_id
    }
    assert_difference("Player.count") do
      post players_url, params: { player: new_player_attrs }, as: :json
    end

    assert_response :created
  end

  test "should show player" do
    get player_url(@player), as: :json
    assert_response :success
  end

  test "should update player" do
    patch player_url(@player), params: { player: { email: @player.email, facebook_id: @player.facebook_id, name: @player.name } }, as: :json
    assert_response :success
  end

  test "should destroy player" do
    assert_difference("Player.count", -1) do
      delete player_url(@player), as: :json
    end

    assert_response :no_content
  end
end

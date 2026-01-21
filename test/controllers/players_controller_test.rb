require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  fixtures :players, :users # Added fixture loading

  setup do
    @player = players(:player_one) # Corrected fixture label
    @admin_user = users(:admin) # From users.yml
    @auth_headers = admin_auth_headers(@admin_user)
  end

  test "should get unauthorized on index without token" do
    get players_url, as: :json
    assert_response :unauthorized
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

  test "should get unauthorized on show without token" do
    get player_url(@player), as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on update without token" do
    patch player_url(@player), params: { player: { email: @player.email, facebook_id: @player.facebook_id, name: @player.name } }, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on update without token destroy player" do
    delete player_url(@player), as: :json
    assert_response :unauthorized
  end

  test "should get all players" do
    get players_url, headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_not_empty(response_json)
  end

  test "should return player info" do
    @player_headers = player_auth_headers(@player)
    get player_url(@player), headers: @player_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_not_empty(response_json)
  end

  test "should login player" do
    @player.update!(password: "password123")
    post login_players_url, params: { email: @player.email, password: "password123" }, as: :json
    assert_response :success
    assert_includes response.parsed_body, "token"
  end

  test "should not login player with wrong password" do
    @player.update!(password: "password123")
    post login_players_url, params: { email: @player.email, password: "wrong" }, as: :json
    assert_response :unauthorized
  end

  test "should login google player" do
    post google_login_players_url, params: { google_id: "google123", email: "google@example.com", name: "Google User" }, as: :json
    assert_response :created
    assert_includes response.parsed_body, "token"
  end
end

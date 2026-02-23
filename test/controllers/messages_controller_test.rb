require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  setup do
    @user = users(:user_one)
    @other_user = users(:user_two)
    @auth_headers = admin_auth_headers(@user)
  end

  test "should get index when authenticated" do
    get messages_url, headers: @auth_headers, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  test "should get unauthorized on index without token" do
    get messages_url, as: :json
    assert_response :unauthorized
  end

  test "should get show (conversation with user) when authenticated" do
    get message_url(@other_user), headers: @auth_headers, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  test "should create message when authenticated" do
    assert_difference("Message.count", 1) do
      post messages_url,
        params: { message: { receiver_id: @other_user.id, content: "Hello!" } },
        headers: @auth_headers,
        as: :json
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Hello!", json["content"]
    assert_equal @other_user.id, json["receiver_id"]
  end

  test "should not create message with invalid params" do
    assert_no_difference("Message.count") do
      post messages_url,
        params: { message: { receiver_id: @other_user.id, content: "" } },
        headers: @auth_headers,
        as: :json
    end
    assert_response :unprocessable_entity
  end
end

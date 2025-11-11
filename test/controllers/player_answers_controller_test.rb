require "test_helper"

class PlayerAnswersControllerTest < ActionDispatch::IntegrationTest
  fixtures :players
  fixtures :categories, :clinical_cases, :questions, :answers
   setup do
      @player_one = players(:player_one)
      @auth_headers = player_auth_headers(@player_one)
      @json_headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
      @question_one = questions(:one)
      @question_two = questions(:two)
      @answer_one  = answers(:one)
      @answer_three  = answers(:three)
   end
  test "should get unauthorized on index without token" do
    get player_answers_url
    assert_response :unauthorized
  end

  test "should get index with valid token" do
    # Assuming you have some player_answers fixtures for @player_one
    # If not, you might need to create them programmatically in setup or within the test
    get player_answers_url, headers: @auth_headers
    assert_response :success
  end

  test "should create new player answer records with valid parameters and token" do
    valid_payload = {
      player_answers: [
        { question_id: @question_one.id, answer_id: @answer_one.id },
        { question_id: @question_two.id, answer_id: @answer_three.id }
      ]
    }.to_json

    # Combine auth headers with JSON headers
    headers_with_auth = @auth_headers.merge(@json_headers)

    assert_changes "PlayerAnswer.count", from: PlayerAnswer.count, to: PlayerAnswer.count + 2 do
      post player_answers_url, params: valid_payload, headers: headers_with_auth
    end

    assert_response :created # 201 Created
    json_response = JSON.parse(response.body)
    assert_equal "Answers saved successfully!", json_response["message"]

    # Verify that the answers are associated with the current player
    assert @player_one.player_answers.exists?(question_id: @question_one.id, answer_id: @answer_one.id)
    assert @player_one.player_answers.exists?(question_id: @question_two.id, answer_id: @answer_three.id)
  end

  test "should not create player answer records with invalid parameters and token" do
    invalid_payload = {
      player_answers: [
        { question_id: 1, answer_id: 3 },
        { answer_id: 4 } # Missing question_id, assuming validation
      ]
    }.to_json

    headers_with_auth = @auth_headers.merge(@json_headers)

    # Note: `assert_no_changes` is important here as nothing should be saved
    assert_no_changes "PlayerAnswer.count" do
      post player_answers_url, params: invalid_payload, headers: headers_with_auth
    end

    assert_response :unprocessable_entity # 422 Unprocessable Entity
    # The error message depends on your model's validations and controller's error handling
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Question must exist"
    assert_includes json_response["errors"], "Answer must exist"
  end

  test "should not create player answer records without token" do
    valid_payload = {
      player_answers: [
        { question_id: 1, answer_id: 3 }
      ]
    }.to_json

    # Send without authentication headers
    post player_answers_url, params: valid_payload, headers: @json_headers
    assert_response :unauthorized # Expect 401 Unauthorized
    # assert_no_changes "PlayerAnswer.count"
  end

  test "should return bad request if player_answers key is missing" do
    missing_key_payload = {
      some_other_key: "value"
    }.to_json

    headers_with_auth = @auth_headers.merge(@json_headers)

    assert_no_changes "PlayerAnswer.count" do
      post player_answers_url, params: missing_key_payload, headers: headers_with_auth
    end

    assert_response :bad_request # 400 Bad Request (ActionController::ParameterMissing)
  end

  test "should handle empty player_answers array gracefully" do
    empty_payload = { player_answers: [] }.to_json

    headers_with_auth = @auth_headers.merge(@json_headers)

    assert_no_changes "PlayerAnswer.count" do
      post player_answers_url, params: empty_payload, headers: headers_with_auth
    end

    assert_response :bad_request # Or :ok if you prefer 200 for empty success
    json_response = JSON.parse(response.body)
    assert_equal "param is missing or the value is empty or invalid: player_answers", json_response["error"]
  end
end

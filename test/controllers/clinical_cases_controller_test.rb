require "test_helper"

class ClinicalCasesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :categories, :clinical_cases, :questions, :answers

  setup do
    @admin_user = users(:admin) # From users.yml
    @auth_headers = admin_auth_headers(@admin_user)
    @category = categories(:one) # From categories.yml
    # Ensure clinical_cases(:one) exists and has associated questions and answers from fixtures
    # For simplicity, we'll use clinical_cases(:one) which should be defined in clinical_cases.yml
    # and have related questions in questions.yml, and answers in answers.yml linked back.
    @existing_clinical_case = clinical_cases(:one)


    @valid_clinical_case_attrs = {
      name: "New Case Title", # Changed from title
      description: "A description for the new case.",
      category_id: @category.id,
      questions_attributes: [
        {
          text: "What is the primary symptom for this new case?",
          # explanation: "This is important to know for diagnosis.", # Removed
          # points: 10, # Removed
          answers_attributes: [
            { text: "Symptom Answer A (Correct)", is_correct: true, description: "This is the correct primary symptom." },
            { text: "Symptom Answer B (Incorrect)", is_correct: false, description: "This is not the primary symptom." }
          ]
        }
      ]
    }

    @invalid_clinical_case_attrs = {
      name: "", # Invalid: name is blank, Changed from title
      description: "A description for an invalid case.",
      category_id: @category.id # Assuming category is valid
    }
  end

  # --- Authentication Tests ---
  test "should get unauthorized on index without token" do
    get clinical_cases_url, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on show without token" do
    get clinical_case_url(@existing_clinical_case), as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on create without token" do
    post clinical_cases_url, params: { clinical_case: @valid_clinical_case_attrs }, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on update without token" do
    put clinical_case_url(@existing_clinical_case), params: { clinical_case: { name: "Updated Title Attempt" } }, as: :json # Changed from title
    assert_response :unauthorized
  end

  test "should get unauthorized on destroy without token" do
    delete clinical_case_url(@existing_clinical_case), as: :json
    assert_response :unauthorized
  end

  # --- CRUD Tests (as Admin) ---
  test "should get index of clinical_cases when authenticated" do
    get clinical_cases_url, headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_not_empty response_json["clinical_cases"], "Response should contain clinical cases"
  end

  test "should create clinical_case with nested attributes when authenticated" do
    assert_difference("ClinicalCase.count", 1) do
      assert_difference("Question.count", @valid_clinical_case_attrs[:questions_attributes].size) do
        # Assuming the first question has 2 answers as defined in @valid_clinical_case_attrs
        num_answers_in_first_question = @valid_clinical_case_attrs[:questions_attributes][0][:answers_attributes].size
        assert_difference("Answer.count", num_answers_in_first_question) do
          post clinical_cases_url, params: { clinical_case: @valid_clinical_case_attrs }, headers: @auth_headers, as: :json
        end
      end
    end
    assert_response :created
    response_json = JSON.parse(response.body)
    assert_equal @valid_clinical_case_attrs[:name], response_json["name"] # Changed from title
    assert_equal @valid_clinical_case_attrs[:questions_attributes].size, response_json["questions"].size, "Should create the correct number of questions"
    assert_equal @valid_clinical_case_attrs[:questions_attributes][0][:answers_attributes].size, response_json["questions"][0]["answers"].size, "Should create the correct number of answers for the first question"
  end

  test "should show clinical_case with questions and answers when authenticated" do
    get clinical_case_url(@existing_clinical_case), headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_equal @existing_clinical_case.name, response_json["name"] # Changed from title
    assert_not_nil response_json["questions"], "Should include questions"
    # Check if the first question has answers, if questions exist
    if response_json["questions"]&.first
      assert_not_nil response_json["questions"][0]["answers"], "Should include answers for questions if questions exist"
    end
  end

  test "should update clinical_case (title and add a question) when authenticated" do
    updated_title = "Updated Case Title Special"

    # It's important that question_id for existing questions is not provided unless updating that specific question.
    # For adding new questions, no 'id' should be present in the attributes hash.
    update_params = {
      name: updated_title, # Changed from title
      questions_attributes: [
        # This represents adding a new question
        {
          text: "A brand new question for update?",
          # explanation: "New explanation for update.", # Removed
          # points: 5, # Removed
          answers_attributes: [
            { text: "New Answer A for update (Correct)", is_correct: true }
          ]
        }
      ]
    }

    initial_question_count = @existing_clinical_case.questions.count
    initial_answer_count = @existing_clinical_case.questions.sum { |q| q.answers.count }

    new_question_answer_count = update_params[:questions_attributes][0][:answers_attributes].size

    assert_difference("Question.count", 1, "A new question should be added") do
      assert_difference("Answer.count", new_question_answer_count, "Answers for the new question should be added") do
        put clinical_case_url(@existing_clinical_case), params: { clinical_case: update_params }, headers: @auth_headers, as: :json
      end
    end

    assert_response :success
    @existing_clinical_case.reload

    assert_equal updated_title, @existing_clinical_case.name # Changed from title
    assert_equal initial_question_count + 1, @existing_clinical_case.questions.count, "Question count should increment by 1"
    assert @existing_clinical_case.questions.any? { |q| q.text == "A brand new question for update?" }
  end

  test "should correctly handle _destroy for nested questions on update" do
    # Ensure the clinical case has at least one question to destroy
    # Create a specific case with a question for this test to avoid fixture side effects
    test_case = ClinicalCase.create!(name: "Case for destroying question", category: @category, description: "Test") # Changed from title
    question_to_destroy = test_case.questions.create!(text: "To be destroyed") # Removed points

    assert_not_nil question_to_destroy, "Test setup failed: question to destroy is nil"

    assert_difference("Question.count", -1) do
      put clinical_case_url(test_case), params: {
        clinical_case: {
          questions_attributes: [
            { id: question_to_destroy.id, _destroy: "1" } # Use '1' or true for _destroy
          ]
        }
      }, headers: @auth_headers, as: :json
    end
    assert_response :success
    assert_not Question.exists?(question_to_destroy.id), "Question should be destroyed"
  end

  test "should destroy clinical_case when authenticated" do
    # Create a new case to destroy to avoid fixture dependency issues
    case_to_destroy = ClinicalCase.create!(name: "To Be Deleted Case", description: "Delete me please", category: @category) # Changed from title
    assert_difference("ClinicalCase.count", -1) do
      delete clinical_case_url(case_to_destroy), headers: @auth_headers, as: :json
    end
    assert_response :no_content
  end

  # --- Validation Tests ---
  test "should not create clinical_case with invalid data" do
    assert_no_difference("ClinicalCase.count") do
      post clinical_cases_url, params: { clinical_case: @invalid_clinical_case_attrs }, headers: @auth_headers, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "should not update clinical_case with invalid data" do
    original_name = @existing_clinical_case.name # Changed from title
    put clinical_case_url(@existing_clinical_case), params: { clinical_case: { name: "" } }, headers: @auth_headers, as: :json # Changed from title
    assert_response :unprocessable_entity
    @existing_clinical_case.reload
    @existing_clinical_case.reload
    assert_equal original_name, @existing_clinical_case.name # Changed from title
  end

  test "should allow player to create clinical_case and force pending status" do
    player_user = users(:user_one) # Assuming this is a player role (0)
    player_auth_headers = admin_auth_headers(player_user) # reusing helper for player token

    assert_difference("ClinicalCase.count", 1) do
      post clinical_cases_url, params: { clinical_case: @valid_clinical_case_attrs.merge(status: "published") }, headers: player_auth_headers, as: :json
    end
    assert_response :created
    response_json = JSON.parse(response.body)
    assert_equal "pending", response_json["status"], "Player contribution should be forced to pending"
  end
end

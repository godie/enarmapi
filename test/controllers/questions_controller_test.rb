require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :categories, :clinical_cases, :questions, :answers

  setup do
    @admin_user = users(:admin)
    @auth_headers = admin_auth_headers(@admin_user)

    # Use a clinical case that is known to exist from fixtures
    @clinical_case = clinical_cases(:one)
    # Use a question that belongs to @clinical_case from fixtures
    @existing_question = @clinical_case.questions.first
    # Fallback if clinical_cases(:one) has no questions in fixtures
    if @existing_question.nil?
        @existing_question = questions(:one) # General question, ensure it's linked to @clinical_case or adjust
        @clinical_case = @existing_question.clinical_case # Ensure @clinical_case is the one for @existing_question
        unless @clinical_case
          # If questions(:one) is not associated with any clinical case, create one.
          @clinical_case = ClinicalCase.create!(category: categories(:one), title: "Case for Question", description: "Desc")
          @existing_question.update!(clinical_case: @clinical_case)
        end
    end


    @valid_question_attrs = {
      text: "What is the next step in management?",
      explanation: "Consider all options.",
      points: 15,
      answers_attributes: [
        { text: "Option X (Correct)", is_correct: true, description: "This is the best next step." },
        { text: "Option Y (Incorrect)", is_correct: false, description: "This is not advisable." }
      ]
    }

    @invalid_question_attrs = {
      text: "", # Invalid: text is blank
      points: 10
    }
  end

  # --- Authentication Tests ---
  test "should get unauthorized on index without token" do
    get clinical_case_questions_url(@clinical_case), as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on show without token" do
    get clinical_case_question_url(@clinical_case, @existing_question), as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on create without token" do
    post clinical_case_questions_url(@clinical_case), params: { question: @valid_question_attrs }, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on update without token" do
    put clinical_case_question_url(@clinical_case, @existing_question), params: { question: { text: "New text" } }, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on destroy without token" do
    delete clinical_case_question_url(@clinical_case, @existing_question), as: :json
    assert_response :unauthorized
  end

  # --- CRUD Tests (as Admin) ---
  test "should get index of questions for a clinical_case when authenticated" do
    get clinical_case_questions_url(@clinical_case), headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_not_empty response_json, "Response should contain questions"
    # Further check if the questions belong to the clinical case if necessary
  end

  test "should create question with nested answers for a clinical_case when authenticated" do
    assert_difference("@clinical_case.questions.count", 1) do
      assert_difference("Answer.count", @valid_question_attrs[:answers_attributes].size) do
        post clinical_case_questions_url(@clinical_case), params: { question: @valid_question_attrs }, headers: @auth_headers, as: :json
      end
    end
    assert_response :created
    response_json = JSON.parse(response.body)
    assert_equal @valid_question_attrs[:text], response_json["text"]
    assert_equal @valid_question_attrs[:answers_attributes].size, response_json["answers"].size
  end

  test "should show question with answers when authenticated" do
    get clinical_case_question_url(@clinical_case, @existing_question), headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_equal @existing_question.text, response_json["text"]
    assert_not_nil response_json["answers"], "Should include answers"
  end

  test "should update question and its nested answers when authenticated" do
    updated_text = "Updated Question Text for real?"
    # Add a new answer, update an existing one, and remove one (if possible)
    existing_answer_to_update = @existing_question.answers.first
    answer_to_destroy = @existing_question.answers.second

    update_params = {
      text: updated_text,
      answers_attributes: [
        # Add a new answer
        { text: "Brand New Answer", is_correct: false, description: "Just added" }
      ]
    }
    # Conditionally add update for existing answer
    if existing_answer_to_update
        update_params[:answers_attributes] << { id: existing_answer_to_update.id, text: "Updated Existing Answer Text" }
    end
    # Conditionally add destroy for another answer
    if answer_to_destroy && existing_answer_to_update && answer_to_destroy.id != existing_answer_to_update.id
        update_params[:answers_attributes] << { id: answer_to_destroy.id, _destroy: "1" }
    elsif !answer_to_destroy && @existing_question.answers.count >=1 && existing_answer_to_update # if only one answer, it's already in existing_answer_to_update
      # This case means there was only one answer, and we can't destroy it while also updating it simply.
      # The test for destroying answers is better handled in isolation.
    end

    initial_answer_count = @existing_question.answers.count
    expected_answer_change = 1 # for the new answer
    if existing_answer_to_update # no change in count for update
    end
    if answer_to_destroy && existing_answer_to_update && answer_to_destroy.id != existing_answer_to_update.id
        expected_answer_change -=1 # one destroyed
    end


    assert_difference("@existing_question.answers.count", expected_answer_change) do
        put clinical_case_question_url(@clinical_case, @existing_question), params: { question: update_params }, headers: @auth_headers, as: :json
    end

    assert_response :success
    @existing_question.reload
    assert_equal updated_text, @existing_question.text
    assert @existing_question.answers.any? { |a| a.text == "Brand New Answer" }
    if existing_answer_to_update
        assert existing_answer_to_update.reload.text == "Updated Existing Answer Text"
    end
    if answer_to_destroy && existing_answer_to_update && answer_to_destroy.id != existing_answer_to_update.id
        assert_not Answer.exists?(answer_to_destroy.id)
    end
  end

  test "should destroy question when authenticated" do
    # Create a question specifically for this test to avoid side effects
    question_to_destroy = @clinical_case.questions.create!(text: "To be deleted soon", points: 1)
    assert_difference("@clinical_case.questions.count", -1) do
      delete clinical_case_question_url(@clinical_case, question_to_destroy), headers: @auth_headers, as: :json
    end
    assert_response :no_content
  end

  # --- Validation Tests ---
  test "should not create question with invalid data" do
    assert_no_difference("@clinical_case.questions.count") do
      post clinical_case_questions_url(@clinical_case), params: { question: @invalid_question_attrs }, headers: @auth_headers, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "should not update question with invalid data" do
    original_text = @existing_question.text
    put clinical_case_question_url(@clinical_case, @existing_question), params: { question: { text: "" } }, headers: @auth_headers, as: :json
    assert_response :unprocessable_entity
    @existing_question.reload
    assert_equal original_text, @existing_question.text
  end

  test "should correctly handle _destroy for nested answers on update" do
    # Setup: ensure question has at least one answer
    question_for_test = @clinical_case.questions.create!(text: "Test question for destroying answers", points: 5)
    answer_to_destroy = question_for_test.answers.create!(text: "Answer to be destroyed", is_correct: false)

    assert_difference("question_for_test.answers.count", -1) do
      put clinical_case_question_url(@clinical_case, question_for_test), params: {
        question: {
          answers_attributes: [
            { id: answer_to_destroy.id, _destroy: "1" }
          ]
        }
      }, headers: @auth_headers, as: :json
    end
    assert_response :success
    assert_not Answer.exists?(answer_to_destroy.id)
  end
end

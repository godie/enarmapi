require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :categories, :clinical_cases, :questions, :answers

  setup do
    @admin_user = users(:admin)
    @auth_headers = admin_auth_headers(@admin_user)

    @category_one = categories(:one)
    @category_two = categories(:two)
    @clinical_case_one = clinical_cases(:one) # Belongs to category_one

    # Ensure questions(:one) is correctly associated for reliable testing
    @existing_question_in_cc = questions(:one)
    if @existing_question_in_cc.clinical_case != @clinical_case_one || @existing_question_in_cc.category_id.present?
      @existing_question_in_cc.update!(clinical_case: @clinical_case_one, category_id: nil, text: "Question in CC One")
    end

    # Create a standalone question if one doesn't exist or ensure it's correctly set up
    @standalone_question = Question.find_by(text: "Standalone Question Test")
    if @standalone_question.nil?
      @standalone_question = Question.create!(text: "Standalone Question Test", category: @category_two, answers_attributes: [ { text: "Ans SA", is_correct: true } ])
    else
      @standalone_question.update!(category: @category_two, clinical_case_id: nil)
    end


    @valid_question_attrs_for_cc = {
      text: "What is the next step in management for this case?",
      clinical_case_id: @clinical_case_one.id,
      answers_attributes: [
        { text: "Option X (Correct)", is_correct: true, description: "This is the best next step." },
        { text: "Option Y (Incorrect)", is_correct: false, description: "This is not advisable." }
      ]
    }

    @valid_standalone_question_attrs = {
      text: "General medical knowledge question?",
      category_id: @category_two.id,
      answers_attributes: [
        { text: "Fact A (Correct)", is_correct: true },
        { text: "Fact B (Incorrect)", is_correct: false }
      ]
    }

    @invalid_question_attrs_no_text = { # Missing text, but valid association
      text: "",
      category_id: @category_one.id
    }
    @invalid_question_attrs_no_association = {
      text: "Valid text but no association"
    }
    @invalid_question_attrs_both_associations = {
      text: "Valid text, but too many associations",
      clinical_case_id: @clinical_case_one.id,
      category_id: @category_two.id
    }
  end

  # --- Authentication Tests (Now for top-level /questions) ---
  test "should get unauthorized on index without token" do
    get questions_url, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on show without token" do
    get question_url(@existing_question_in_cc), as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on create without token" do
    post questions_url, params: { question: @valid_question_attrs_for_cc }, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on update without token" do
    put question_url(@existing_question_in_cc), params: { question: { text: "New text" } }, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on destroy without token" do
    delete question_url(@existing_question_in_cc), as: :json
    assert_response :unauthorized
  end


  # --- CRUD Tests (as Admin for /questions) ---

  # INDEX Tests
  test "should get index of all questions when authenticated" do
    get questions_url, headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_not_empty response_json
    response_ids = response_json.map { |q| q["id"] }
    assert_includes response_ids, @existing_question_in_cc.id
    assert_includes response_ids, @standalone_question.id
  end

  test "should get index of questions filtered by clinical_case_id" do
    get questions_url(clinical_case_id: @clinical_case_one.id), headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_not_empty response_json, "Response for clinical_case_id filter shouldn't be empty"
    response_json.each do |question|
      assert_equal @clinical_case_one.id, question["clinical_case_id"]
    end
    assert_equal @clinical_case_one.questions.count, response_json.size
  end

  test "should get index of questions filtered by category_id (includes CC and standalone)" do
    sa_q_in_cat_one = Question.create!(text: "SA in Cat One for Filter Test", category: @category_one, answers_attributes: [ { text: "a", is_correct: true } ])
    cc_question_in_cat_one = @clinical_case_one.questions.first # This is @existing_question_in_cc

    get questions_url(category_id: @category_one.id), headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)

    question_ids_in_response = response_json.map { |q| q["id"] }

    assert_includes question_ids_in_response, cc_question_in_cat_one.id
    assert_includes question_ids_in_response, sa_q_in_cat_one.id
    assert_not_includes question_ids_in_response, @standalone_question.id # This one is in category_two

    assert_equal Question.by_category(@category_one.id).count, response_json.size
  end


  # CREATE Tests
  test "should create question associated with a clinical_case" do
    assert_difference("Question.count", 1) do
      assert_difference("Answer.count", @valid_question_attrs_for_cc[:answers_attributes].size) do
        post questions_url, params: { question: @valid_question_attrs_for_cc }, headers: @auth_headers, as: :json
      end
    end
    assert_response :created
    response_json = JSON.parse(response.body)
    created_question = Question.find(response_json["id"])
    assert_equal @valid_question_attrs_for_cc[:text], created_question.text
    assert_equal @clinical_case_one.id, created_question.clinical_case_id
    assert_nil created_question.category_id # Direct category_id should be nil
    assert_equal @valid_question_attrs_for_cc[:answers_attributes].size, created_question.answers.size
  end

  test "should create standalone question associated with a category" do
    assert_difference("Question.count", 1) do
      assert_difference("Answer.count", @valid_standalone_question_attrs[:answers_attributes].size) do
        post questions_url, params: { question: @valid_standalone_question_attrs }, headers: @auth_headers, as: :json
      end
    end
    assert_response :created
    response_json = JSON.parse(response.body)
    created_question = Question.find(response_json["id"])
    assert_equal @valid_standalone_question_attrs[:text], created_question.text
    assert_equal @valid_standalone_question_attrs[:category_id], created_question.category_id
    assert_nil created_question.clinical_case_id
    assert_equal @valid_standalone_question_attrs[:answers_attributes].size, created_question.answers.size
  end

  test "should not create question without clinical_case_id AND category_id" do
    assert_no_difference("Question.count") do
      post questions_url, params: { question: @invalid_question_attrs_no_association }, headers: @auth_headers, as: :json
    end
    assert_response :unprocessable_entity
    response_json = JSON.parse(response.body)
    assert_includes response_json["base"], "La pregunta debe estar asociada a un caso clínico o a una categoría"
  end

  test "should not create question with BOTH clinical_case_id AND category_id" do
    assert_no_difference("Question.count") do
      post questions_url, params: { question: @invalid_question_attrs_both_associations }, headers: @auth_headers, as: :json
    end
    assert_response :unprocessable_entity
    response_json = JSON.parse(response.body)
    assert_includes response_json["base"], "La pregunta no puede estar asociada a un caso clínico y a una categoría directamente"
  end


  # SHOW Test
  test "should show question with answers and correct associations" do
    # Test with question in clinical case
    get question_url(@existing_question_in_cc), headers: @auth_headers, as: :json
    assert_response :success
    response_json_cc = JSON.parse(response.body)
    assert_equal @existing_question_in_cc.text, response_json_cc["text"]
    assert_equal @existing_question_in_cc.clinical_case_id, response_json_cc["clinical_case_id"]
    assert_not_nil response_json_cc["clinical_case"]
    assert_equal @existing_question_in_cc.clinical_case.category.id, response_json_cc["clinical_case"]["category_id"]
    assert_nil response_json_cc["category"] # Direct category object should be null

    # Test with standalone question
    get question_url(@standalone_question), headers: @auth_headers, as: :json
    assert_response :success
    response_json_sa = JSON.parse(response.body)
    assert_equal @standalone_question.text, response_json_sa["text"]
    assert_equal @standalone_question.category_id, response_json_sa["category_id"]
    assert_not_nil response_json_sa["category"]
    assert_nil response_json_sa["clinical_case_id"]
    assert_nil response_json_sa["clinical_case"]
  end

  # UPDATE Test
  test "should update question text and its nested answers" do
    updated_text = "Updated Question Text here"
    existing_answer = @existing_question_in_cc.answers.first
    new_answer_text = "Freshly Added Answer"
    updated_existing_answer_text = "Modified Existing Answer"

    update_params = {
      text: updated_text,
      answers_attributes: [ { text: new_answer_text, is_correct: true } ]
    }
    if existing_answer
      update_params[:answers_attributes] << { id: existing_answer.id, text: updated_existing_answer_text }
    end

    expected_answer_change = 1 # Adding one new answer

    assert_difference("@existing_question_in_cc.answers.count", expected_answer_change) do
      put question_url(@existing_question_in_cc), params: { question: update_params }, headers: @auth_headers, as: :json
    end

    assert_response :success
    @existing_question_in_cc.reload
    assert_equal updated_text, @existing_question_in_cc.text
    assert @existing_question_in_cc.answers.any? { |a| a.text == new_answer_text }
    if existing_answer
      assert existing_answer.reload.text == updated_existing_answer_text
    end
  end

  test "should be able to change question from clinical_case to standalone category" do
    assert_not_nil @existing_question_in_cc.clinical_case_id
    target_category_id = @category_two.id

    put question_url(@existing_question_in_cc), params: { question: { clinical_case_id: nil, category_id: target_category_id } }, headers: @auth_headers, as: :json
    assert_response :success
    @existing_question_in_cc.reload
    assert_nil @existing_question_in_cc.clinical_case_id
    assert_equal target_category_id, @existing_question_in_cc.category_id
  end

  test "should be able to change question from standalone category to clinical_case" do
    assert_not_nil @standalone_question.category_id
    assert_nil @standalone_question.clinical_case_id
    target_clinical_case_id = @clinical_case_one.id

    put question_url(@standalone_question), params: { question: { category_id: nil, clinical_case_id: target_clinical_case_id } }, headers: @auth_headers, as: :json
    assert_response :success
    @standalone_question.reload
    assert_nil @standalone_question.category_id
    assert_equal target_clinical_case_id, @standalone_question.clinical_case_id
  end


  # DESTROY Test
  test "should destroy question" do
    question_to_destroy = Question.create!(text: "Delete me", category: @category_one)
    assert_difference("Question.count", -1) do
      delete question_url(question_to_destroy), headers: @auth_headers, as: :json
    end
    assert_response :no_content
  end


  # --- Validation Tests (for /questions) ---
  test "should not create question with invalid data (blank text)" do
    assert_no_difference("Question.count") do
      post questions_url, params: { question: @invalid_question_attrs_no_text }, headers: @auth_headers, as: :json
    end
    assert_response :unprocessable_entity
    response_json = JSON.parse(response.body)
    assert_includes response_json["text"], "can't be blank"
  end

  test "should not update question with invalid data (blank text)" do
    original_text = @existing_question_in_cc.text
    put question_url(@existing_question_in_cc), params: { question: { text: "" } }, headers: @auth_headers, as: :json
    assert_response :unprocessable_entity
    @existing_question_in_cc.reload
    assert_equal original_text, @existing_question_in_cc.text
  end

  test "should correctly handle _destroy for nested answers on update" do
    question_with_answers = Question.create!(text: "Test Q for destroying answers", category: @category_one)
    answer_to_keep = question_with_answers.answers.create!(text: "Keep me", is_correct: true)
    answer_to_destroy = question_with_answers.answers.create!(text: "Delete me", is_correct: false)

    assert_difference("question_with_answers.answers.count", -1) do
      put question_url(question_with_answers), params: {
        question: {
          answers_attributes: [ { id: answer_to_destroy.id, _destroy: "1" } ]
        }
      }, headers: @auth_headers, as: :json
    end
    assert_response :success
    assert_not Answer.exists?(answer_to_destroy.id)
    assert Answer.exists?(answer_to_keep.id)
  end
end

require "test_helper"

class ExamsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :categories, :clinical_cases, :questions, :exams, :exam_questions # Added categories, clinical_cases

  setup do
    @admin_user = users(:admin)
    @auth_headers = admin_auth_headers(@admin_user)

    # Questions to be used for exam associations
    @question1 = questions(:one) # From questions.yml
    @question2 = questions(:two) # From questions.yml

    # Simplified setup: Rely on fixtures being loaded correctly.
    # Ensure questions(:one) and questions(:two) are valid and associated with clinical_cases(:one) / clinical_cases(:two) in fixtures.
    # Ensure exams(:one) is valid and has associated exam_questions in fixtures.
    # The fixtures yml files are the source of truth for these associations.

    @existing_exam = exams(:exam_one_urgencias) # Changed from exams(:one)

    # Ensure @question1 and @question2 are valid for use in @valid_exam_attrs
    # If they might be nil due to sparse fixtures, this setup might need adjustment,
    # but the goal is to rely on well-defined fixtures.
    if @question1.nil? || @question2.nil?
      raise "Fixture setup error: questions :one or :two not found. Ensure questions.yml is populated and correctly associated."
    end
    if @existing_exam.nil?
      raise "Fixture setup error: exams :one not found. Ensure exams.yml is populated."
    end
    # It's also good practice for @existing_exam to have at least one exam_question for tests that rely on it.
    # This can be defined in exam_questions.yml. Example:
    # eq_one_q_one:
    #   exam: exam_one
    #   question: one
    #   points: 10
    #   position: 1

    @valid_exam_attrs = {
      name: "New Comprehensive Exam",
      description: "A detailed exam covering various topics.",
      # available_from: Time.current, # Removed
      # available_to: 1.month.from_now, # Removed
      exam_questions_attributes: [
        { question_id: @question1.id, points: 10, position: 1 },
        { question_id: @question2.id, points: 5, position: 2 }
      ]
    }

    @invalid_exam_attrs = {
      name: "", # Invalid: name is blank
      description: "This exam is invalid."
    }
  end

  # --- Authentication Tests ---
  test "should get unauthorized on index without token" do
    get exams_url, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on show without token" do
    get exam_url(@existing_exam), as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on create without token" do
    post exams_url, params: { exam: @valid_exam_attrs }, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on update without token" do
    put exam_url(@existing_exam), params: { exam: { name: "New Name Attempt" } }, as: :json
    assert_response :unauthorized
  end

  test "should get unauthorized on destroy without token" do
    delete exam_url(@existing_exam), as: :json
    assert_response :unauthorized
  end

  # --- CRUD Tests (as Admin) ---
  test "should get index of exams when authenticated" do
    get exams_url, headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_not_empty response_json, "Response should contain exams"
  end

  test "should create exam with nested exam_questions when authenticated" do
    assert_difference("Exam.count", 1) do
      assert_difference("ExamQuestion.count", @valid_exam_attrs[:exam_questions_attributes].size) do
        post exams_url, params: { exam: @valid_exam_attrs }, headers: @auth_headers, as: :json
      end
    end
    assert_response :created
    response_json = JSON.parse(response.body)
    assert_equal @valid_exam_attrs[:name], response_json["name"]
    assert_equal @valid_exam_attrs[:exam_questions_attributes].size, response_json["exam_questions"].size
    # Check if points and position are correctly set for the first exam_question
    first_eq_attrs = @valid_exam_attrs[:exam_questions_attributes][0]
    response_eq = response_json["exam_questions"].find { |eq| eq["question_id"] == first_eq_attrs[:question_id] }
    assert_equal first_eq_attrs[:points], response_eq["points"]
    assert_equal first_eq_attrs[:position], response_eq["position"]
  end

  test "should show exam with its questions (points, position) when authenticated" do
    get exam_url(@existing_exam), headers: @auth_headers, as: :json
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_equal @existing_exam.name, response_json["name"]
    assert_not_nil response_json["exam_questions"], "Should include exam_questions"
    if @existing_exam.exam_questions.any?
      # Check details of the first exam_question from fixture/setup
      expected_eq = @existing_exam.exam_questions.order(:position).first
      response_eq = response_json["exam_questions"].find { |eq| eq["question_id"] == expected_eq.question_id }
      assert_equal expected_eq.points, response_eq["points"]
      assert_equal expected_eq.position, response_eq["position"]
    end
  end

  test "should update exam and its exam_questions when authenticated" do
    updated_name = "Updated Exam Name Super"
    # Modify existing ExamQuestion, add a new one, remove one
    existing_eq_to_update = @existing_exam.exam_questions.first
    # For adding a new one, ensure @question2 is not already part of @existing_exam from fixtures directly
    # For removing one, pick one if there are multiple, or the only one if that's the case.
    eq_to_destroy = @existing_exam.exam_questions.count > 1 ? @existing_exam.exam_questions.second : nil

    update_params = {
      name: updated_name,
      exam_questions_attributes: []
    }

    # Update existing EQ
    if existing_eq_to_update
      update_params[:exam_questions_attributes] << { id: existing_eq_to_update.id, points: 20 } # Update points
    end

    # Add new EQ (ensure @question2 is not already in this exam)
    unless @existing_exam.exam_questions.any? { |eq| eq.question_id == @question2.id }
      update_params[:exam_questions_attributes] << { question_id: @question2.id, points: 15, position: (existing_eq_to_update&.position || 0) + 1 }
    end

    # Destroy an EQ
    if eq_to_destroy
      update_params[:exam_questions_attributes] << { id: eq_to_destroy.id, _destroy: "1" }
    end

    # Calculate expected change in ExamQuestion count
    expected_eq_count_change = 0
    expected_eq_count_change += 1 unless @existing_exam.exam_questions.any? { |eq| eq.question_id == @question2.id } # for new one
    expected_eq_count_change -= 1 if eq_to_destroy # for destroyed one

    assert_difference("ExamQuestion.count", expected_eq_count_change) do
      put exam_url(@existing_exam), params: { exam: update_params }, headers: @auth_headers, as: :json
    end

    assert_response :success
    @existing_exam.reload
    assert_equal updated_name, @existing_exam.name
    if existing_eq_to_update
      assert_equal 20, existing_eq_to_update.reload.points
    end
    # The logic for adding @question2 was conditional:
    # unless @existing_exam.exam_questions.any? { |eq| eq.question_id == @question2.id }
    # And eq_to_destroy was set to the exam_question for @question2.
    # So, if it was destroyed, this assertion for its existence with 15 points is incorrect.
    # The assert_not ExamQuestion.exists?(eq_to_destroy.id) later will confirm its destruction.
    # Thus, we should not assert its presence here if it was targeted for destruction.
    if eq_to_destroy && eq_to_destroy.question_id == @question2.id
      # If @question2's exam_question was destroyed, we don't assert for its presence with 15 points.
    else
      # If @question2's exam_question was NOT destroyed (e.g. it wasn't present to begin with, so it was added), then assert.
      # This also covers the case where @question2 was not eq_to_destroy and was not pre-existing (so it was added).
      assert @existing_exam.exam_questions.any? { |eq| eq.question_id == @question2.id && eq.points == 15 }, "ExamQuestion for @question2 with 15 points should exist if not destroyed"
    end
    if eq_to_destroy
      assert_not ExamQuestion.exists?(eq_to_destroy.id)
    end
  end

  test "should destroy exam and its exam_questions when authenticated" do
    # Create a dedicated exam for this test to avoid fixture interference
    exam_to_destroy = Exam.create!(name: "To Be Deleted Exam", description: "Delete this one.")
    ExamQuestion.create!(exam: exam_to_destroy, question: @question1, points: 10, position: 1)
    ExamQuestion.create!(exam: exam_to_destroy, question: @question2, points: 5, position: 2)

    assert_difference("Exam.count", -1) do
      assert_difference("ExamQuestion.count", -exam_to_destroy.exam_questions.count) do # All its EQs should be deleted
        delete exam_url(exam_to_destroy), headers: @auth_headers, as: :json
      end
    end
    assert_response :no_content
  end

  # --- Validation Tests ---
  test "should not create exam with invalid data" do
    assert_no_difference("Exam.count") do
      post exams_url, params: { exam: @invalid_exam_attrs }, headers: @auth_headers, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "should not update exam with invalid data" do
    original_name = @existing_exam.name
    put exam_url(@existing_exam), params: { exam: { name: "" } }, headers: @auth_headers, as: :json
    assert_response :unprocessable_entity
    @existing_exam.reload
    assert_equal original_name, @existing_exam.name
  end

  test "should not create exam if nested exam_questions_attributes are invalid" do
    # Example: question_id is missing
    invalid_eq_attrs = @valid_exam_attrs.deep_dup
    invalid_eq_attrs[:exam_questions_attributes][0][:question_id] = nil

    assert_no_difference([ "Exam.count", "ExamQuestion.count" ]) do
      post exams_url, params: { exam: invalid_eq_attrs }, headers: @auth_headers, as: :json
    end
    assert_response :unprocessable_entity # Or :bad_request depending on how model handles this
  end
end

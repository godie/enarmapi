require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:clinical_case)
    should have_one(:category).through(:clinical_case)
    should have_many(:answers).dependent(:destroy)
    should accept_nested_attributes_for(:answers).allow_destroy(true)

    should have_many(:player_answers)
    should have_many(:practicing_players).through(:player_answers).source(:player)

    should have_many(:exam_questions)
    should have_many(:exams).through(:exam_questions)
  end

  context "validations" do
    should validate_presence_of(:text)

    # clinical_case_id is `null: false` in DB schema.
    # `belongs_to :clinical_case` implies presence validation by default.
    should "be invalid without a clinical_case" do
      question = Question.new(text: "A question text here.")
      assert_not question.valid?, "Question should be invalid without a clinical_case."
      assert_includes question.errors[:clinical_case], "must exist"
    end
  end

  setup do
    @category_one = categories(:one)
    @clinical_case_one = clinical_cases(:one) # Belongs to @category_one
    @player_one = players(:player_one)
  end

  test "should be valid with text and an associated clinical_case" do
    question = Question.new(text: "Is this a valid question?", clinical_case: @clinical_case_one)
    assert question.valid?, question.errors.full_messages.join(", ")
  end

  test "can accept nested attributes for creating answers" do
    attributes = {
      text: "Question with several nested answers",
      clinical_case_id: @clinical_case_one.id,
      answers_attributes: [
        { text: "Nested Answer A (Correct)", is_correct: true },
        { text: "Nested Answer B (Incorrect)", is_correct: false },
        { description: "Nested Answer C (Only description)", is_correct: false } # Answer's `text` can be nil
      ]
    }
    question = Question.new(attributes)
    assert question.valid?, "Question with nested answers should be valid. Errors: #{question.errors.full_messages.join(", ")}"
    assert question.save, "Failed to save question with nested answers. Errors: #{question.errors.full_messages.join(", ")}"
    question.reload
    assert_equal 3, question.answers.count, "Should have created 3 answers"
    assert_equal "Nested Answer A (Correct)", question.answers.find_by(is_correct: true)&.text
  end

  test "destroying a question also destroys its associated answers but not its clinical_case" do
    question_for_deletion = Question.create!(text: "This question will be deleted.", clinical_case: @clinical_case_one)
    Answer.create!(question: question_for_deletion, text: "Answer 1 for deletion test", is_correct: true)
    Answer.create!(question: question_for_deletion, text: "Answer 2 for deletion test", is_correct: false)

    answer_ids = question_for_deletion.answers.pluck(:id)
    clinical_case_id = question_for_deletion.clinical_case_id
    assert_equal 2, answer_ids.count, "Should have 2 answers before question deletion"

    question_for_deletion.destroy

    assert_raises(ActiveRecord::RecordNotFound) { Question.find(question_for_deletion.id) }
    answer_ids.each do |id|
      assert_raises(ActiveRecord::RecordNotFound, "Answer with ID #{id} should have been destroyed.") { Answer.find(id) }
    end
    assert ClinicalCase.exists?(clinical_case_id), "Associated ClinicalCase should still exist."
  end

  test "can update nested answers' attributes" do
    question_for_update = Question.create!(text: "Question for updating its answers", clinical_case: @clinical_case_one)
    answer_to_update = Answer.create!(text: "Initial Text", question: question_for_update, is_correct: true)

    question_for_update.update!(answers_attributes: [
      { id: answer_to_update.id, text: "Updated Text", is_correct: false }
    ])
    answer_to_update.reload
    assert_equal "Updated Text", answer_to_update.text
    assert_equal false, answer_to_update.is_correct
  end

  test "can destroy nested answers using _destroy flag" do
    question_for_destroy_nested = Question.create!(text: "Q for destroying one of its nested answers", clinical_case: @clinical_case_one)
    ans_kept = Answer.create!(text: "This answer is kept", question: question_for_destroy_nested, is_correct: true)
    ans_destroyed = Answer.create!(text: "This answer is destroyed", question: question_for_destroy_nested, is_correct: false)

    assert_equal 2, question_for_destroy_nested.answers.count

    question_for_destroy_nested.update!(answers_attributes: [
      { id: ans_destroyed.id, _destroy: "1" } # Mark for destruction
    ])
    question_for_destroy_nested.reload

    assert_equal 1, question_for_destroy_nested.answers.count, "Should have one answer remaining"
    assert_equal ans_kept, question_for_destroy_nested.answers.first
    assert_raises(ActiveRecord::RecordNotFound) { Answer.find(ans_destroyed.id) }
  end

  test "category association through clinical_case works" do
    question = Question.new(text: "Test Q for category access", clinical_case: @clinical_case_one)
    # @clinical_case_one is associated with @category_one (categories(:one)) in setup
    assert_equal @category_one, question.category
  end

  context "scopes" do
    setup do
      # Using fresh records for scope tests to avoid interference.
      @cat_scope1 = Category.find_or_create_by!(name: "Scope Category Alpha")
      @cat_scope2 = Category.find_or_create_by!(name: "Scope Category Beta")

      @cc_scope1_cat1 = ClinicalCase.find_or_create_by!(name: "Scope CC1 Cat1", category: @cat_scope1, description: "Desc")
      @cc_scope2_cat1 = ClinicalCase.find_or_create_by!(name: "Scope CC2 Cat1", category: @cat_scope1, description: "Desc")
      @cc_scope1_cat2 = ClinicalCase.find_or_create_by!(name: "Scope CC1 Cat2", category: @cat_scope2, description: "Desc")

      @q_s_c1_cc1 = Question.create!(text: "Q Scope C1 CC1", clinical_case: @cc_scope1_cat1)
      @q_s_c1_cc2 = Question.create!(text: "Q Scope C1 CC2", clinical_case: @cc_scope2_cat1)
      @q_s_c2_cc1 = Question.create!(text: "Q Scope C2 CC1", clinical_case: @cc_scope1_cat2)

      # For :not_practiced_by scope
      @player_scope_test = Player.create!(facebook_id: "fb_q_scopes_#{SecureRandom.hex(4)}")
      # @q_s_c1_cc1 is NOT practiced by @player_scope_test
      # @q_s_c1_cc2 IS practiced by @player_scope_test
      ans_for_q_s_c1_cc2 = Answer.create!(question: @q_s_c1_cc2, text: "Ans for practiced Q", is_correct: true)
      PlayerAnswer.create!(player: @player_scope_test, question: @q_s_c1_cc2, answer: ans_for_q_s_c1_cc2)
    end

    should "return all questions for :with_clinical_case scope (as clinical_case is mandatory)" do
      # Given clinical_case_id is NOT NULL, this scope effectively returns all questions.
      questions_with_case = Question.with_clinical_case
      # Check if all questions created in this context are included.
      # This is a bit broad; better to check specific list if possible, or count.
      assert_includes questions_with_case, @q_s_c1_cc1
      assert_includes questions_with_case, @q_s_c1_cc2
      assert_includes questions_with_case, @q_s_c2_cc1
      assert_equal Question.count, questions_with_case.count # More robust if no other questions exist
    end

    should "return empty for :standalone scope (as clinical_case is mandatory)" do
      # clinical_case_id cannot be NULL due to DB constraint.
      assert_empty Question.standalone, ":standalone scope should be empty."
    end

    should "filter questions by category_id for :by_category scope" do
      questions_in_cat_scope1 = Question.by_category(@cat_scope1.id)
      assert_includes questions_in_cat_scope1, @q_s_c1_cc1
      assert_includes questions_in_cat_scope1, @q_s_c1_cc2
      assert_not_includes questions_in_cat_scope1, @q_s_c2_cc1
      assert_equal 2, questions_in_cat_scope1.count

      questions_in_cat_scope2 = Question.by_category(@cat_scope2.id)
      assert_includes questions_in_cat_scope2, @q_s_c2_cc1
      assert_not_includes questions_in_cat_scope2, @q_s_c1_cc1
      assert_equal 1, questions_in_cat_scope2.count
    end

    should "filter questions by clinical_case_id for :by_clinical_case scope" do
      questions_in_cc1_cat1 = Question.by_clinical_case(@cc_scope1_cat1.id)
      assert_includes questions_in_cc1_cat1, @q_s_c1_cc1
      assert_not_includes questions_in_cc1_cat1, @q_s_c1_cc2
      assert_equal 1, questions_in_cc1_cat1.count
    end

    should "return questions not practiced by a given player for :not_practiced_by scope" do
      # @player_scope_test has practiced @q_s_c1_cc2.
      # @q_s_c1_cc1 and @q_s_c2_cc1 are not practiced by @player_scope_test.
      not_practiced_list = Question.not_practiced_by(@player_scope_test)

      assert_includes not_practiced_list, @q_s_c1_cc1
      assert_includes not_practiced_list, @q_s_c2_cc1
      assert_not_includes not_practiced_list, @q_s_c1_cc2

      # Ensure other questions from general fixtures are also considered if not practiced
      # This depends on the full DB state. For isolated test, count might be more specific.
      # Example: Total questions - practiced questions by this player = not_practiced count for this player.
      total_questions = Question.count
      practiced_by_player_count = @player_scope_test.practiced_questions.count
      assert_equal (total_questions - practiced_by_player_count), not_practiced_list.count
    end
  end
end

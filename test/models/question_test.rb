require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  fixtures :categories, :clinical_cases, :players
  # Associations
  test "should belong to clinical_case" do
    q = Question.new
    assert_respond_to q, :clinical_case
    assert_respond_to q, :clinical_case_id
  end

  test "should have one category through clinical_case" do
    q = Question.new
    assert_respond_to q, :category
  end

  test "should have many answers and they should be dependent destroy" do
    q = Question.new
    assert_respond_to q, :answers

    # Test dependent destroy
    question_with_answers = Question.create!(text: "Q for Answer Destroy Test", clinical_case: clinical_cases(:one))
    ans = Answer.create!(question: question_with_answers, text: "Ans for Q Destroy Test", is_correct: true)
    ans_id = ans.id

    assert_difference "Answer.count", -1 do
      question_with_answers.destroy
    end
    assert_not Answer.exists?(ans_id)
  end

  test "should accept nested attributes for answers and allow destroy" do
    q = Question.new
    assert_respond_to q, :answers_attributes=
    # Further functionality tests for nested attributes are below.
  end

  test "should have many player_answers" do
    q = Question.new
    assert_respond_to q, :player_answers
  end

  test "should have many practicing_players through player_answers" do
    q = Question.new
    assert_respond_to q, :practicing_players
  end

  test "should have many exam_questions" do
    q = Question.new
    assert_respond_to q, :exam_questions
  end

  test "should have many exams through exam_questions" do
    q = Question.new
    assert_respond_to q, :exams
  end

  # Validations
  test "should validate presence of text" do
    question = Question.new(clinical_case: clinical_cases(:one)) # Has clinical_case but no text
    assert_not question.valid?, "Question should be invalid without text"
    assert_includes question.errors[:text], "can't be blank"
  end

  test "should be invalid without a clinical_case" do
    # clinical_case_id is `null: false` in DB schema.
    # `belongs_to :clinical_case` also implies presence by default.
    question = Question.new(text: "A question text without a clinical case.")
    assert_not question.valid?, "Question should be invalid without a clinical_case association"
    assert_includes question.errors[:clinical_case], "must exist"
  end

  # General setup for some tests
  setup do
    @category_one_fix = categories(:one)
    @clinical_case_one_fix = clinical_cases(:one) # Belongs to @category_one_fix
    @player_one_fix = players(:player_one)
  end

  test "should be valid with text and an associated clinical_case" do
    question = Question.new(text: "Is this a valid question text?", clinical_case: @clinical_case_one_fix)
    assert question.valid?, question.errors.full_messages.join(", ")
  end

  # Nested Attributes for Answers - Functionality Tests
  test "can accept and create nested answers" do
    attributes = {
      text: "Question with multiple nested answers for creation",
      clinical_case_id: @clinical_case_one_fix.id,
      answers_attributes: [
        { text: "Nested Answer X (Correct)", is_correct: true },
        { text: "Nested Answer Y (Incorrect)", is_correct: false },
        { description: "Nested Answer Z (Desc only)", is_correct: false } # Answer's `text` can be nil
      ]
    }
    question = Question.new(attributes)
    assert question.valid?, "Q with nested answers (create) should be valid. Errors: #{question.errors.full_messages.join(", ")}"
    assert question.save, "Failed to save Q with nested answers. Errors: #{question.errors.full_messages.join(", ")}"
    question.reload # Reload to fetch answers from DB
    assert_equal 3, question.answers.count, "Should have created 3 answers via nesting"
    assert_equal "Nested Answer X (Correct)", question.answers.find_by(is_correct: true)&.text
  end

  test "can update attributes of nested answers" do
    question_to_update_ans = Question.create!(text: "Q for updating its answers", clinical_case: @clinical_case_one_fix)
    answer_to_update = Answer.create!(text: "Initial Answer Text", question: question_to_update_ans, is_correct: true)

    question_to_update_ans.update!(answers_attributes: [
      { id: answer_to_update.id, text: "Updated Answer Text", is_correct: false }
    ])
    answer_to_update.reload # Fetch updated state from DB
    assert_equal "Updated Answer Text", answer_to_update.text
    assert_equal false, answer_to_update.is_correct
  end

  test "can destroy nested answers using _destroy flag in attributes" do
    q_for_destroy_nested_ans = Question.create!(text: "Q for destroying one of its answers via nesting", clinical_case: @clinical_case_one_fix)
    ans_to_be_kept = Answer.create!(text: "Answer to be kept", question: q_for_destroy_nested_ans, is_correct: true)
    ans_to_be_destroyed = Answer.create!(text: "Answer to be destroyed", question: q_for_destroy_nested_ans, is_correct: false)

    assert_equal 2, q_for_destroy_nested_ans.answers.count, "Should have 2 answers initially"

    q_for_destroy_nested_ans.update!(answers_attributes: [
      { id: ans_to_be_destroyed.id, _destroy: "1" } # Mark for destruction
    ])
    q_for_destroy_nested_ans.reload

    assert_equal 1, q_for_destroy_nested_ans.answers.count, "Should have one answer remaining after _destroy"
    assert_equal ans_to_be_kept, q_for_destroy_nested_ans.answers.first
    assert_raises(ActiveRecord::RecordNotFound) { Answer.find(ans_to_be_destroyed.id) }
  end

  test "category association (has_one :through) works correctly" do
    question = Question.new(text: "Test Q for direct category access", clinical_case: @clinical_case_one_fix)
    # @clinical_case_one_fix is associated with @category_one_fix (categories(:one))
    assert_equal @category_one_fix, question.category
  end

  # Scopes
  def setup_for_scope_tests
    # Clean existing records created by other tests if they interfere.
    # Using find_or_create_by for setup records to make it somewhat idempotent.
    @cat_s1 = Category.find_or_create_by!(name: "QuestionScope Cat Alpha")
    @cat_s2 = Category.find_or_create_by!(name: "QuestionScope Cat Beta")

    @cc_s1_c1 = ClinicalCase.find_or_create_by!(name: "QS CC1 C1", category: @cat_s1, description: "d")
    @cc_s2_c1 = ClinicalCase.find_or_create_by!(name: "QS CC2 C1", category: @cat_s1, description: "d") # Another CC in Cat S1
    @cc_s1_c2 = ClinicalCase.find_or_create_by!(name: "QS CC1 C2", category: @cat_s2, description: "d")

    @q_s_c1_cc1 = Question.find_or_create_by!(text: "QS Q C1 CC1", clinical_case: @cc_s1_c1)
    @q_s_c1_cc2 = Question.find_or_create_by!(text: "QS Q C1 CC2", clinical_case: @cc_s2_c1) # In Cat S1 via CC S2 C1
    @q_s_c2_cc1 = Question.find_or_create_by!(text: "QS Q C2 CC1", clinical_case: @cc_s1_c2) # In Cat S2

    @player_s_test = Player.find_or_create_by!(facebook_id: "fb_q_scopes_player_#{SecureRandom.hex(3)}")
    # @q_s_c1_cc2 is practiced by @player_s_test
    ans_for_q_s_c1_cc2 = Answer.find_or_create_by!(question: @q_s_c1_cc2, text: "Ans for practiced QS Q", is_correct: true)
    PlayerAnswer.find_or_create_by!(player: @player_s_test, question: @q_s_c1_cc2) do |pa|
      pa.answer = ans_for_q_s_c1_cc2
    end
    # @q_s_c1_cc1 and @q_s_c2_cc1 are NOT practiced by @player_s_test
  end

  test "with_clinical_case scope returns all questions (as clinical_case is mandatory)" do
    setup_for_scope_tests
    # Given clinical_case_id is NOT NULL, this scope should effectively return all questions.
    questions_with_case = Question.with_clinical_case

    # Check if all questions created in the scope setup are included.
    assert_includes questions_with_case, @q_s_c1_cc1
    assert_includes questions_with_case, @q_s_c1_cc2
    assert_includes questions_with_case, @q_s_c2_cc1
    # More robust: check count against total if DB is clean or filtered for this test's records.
    # For now, assuming these are the only relevant ones.
    assert questions_with_case.count >= 3 # Should be at least the ones we created.
  end

  test "standalone scope returns empty (as clinical_case is mandatory)" do
    setup_for_scope_tests
    # clinical_case_id cannot be NULL due to DB constraint `null: false`.
    assert_empty Question.standalone, ":standalone scope should be empty due to schema constraints."
  end

  test "by_category scope filters questions by category_id" do
    setup_for_scope_tests
    questions_in_cat_s1 = Question.by_category(@cat_s1.id)
    assert_includes questions_in_cat_s1, @q_s_c1_cc1
    assert_includes questions_in_cat_s1, @q_s_c1_cc2
    assert_not_includes questions_in_cat_s1, @q_s_c2_cc1
    assert_equal 2, questions_in_cat_s1.count # Assuming only these two in @cat_s1 from this setup

    questions_in_cat_s2 = Question.by_category(@cat_s2.id)
    assert_includes questions_in_cat_s2, @q_s_c2_cc1
    assert_not_includes questions_in_cat_s2, @q_s_c1_cc1
    assert_equal 1, questions_in_cat_s2.count # Assuming only this one in @cat_s2
  end

  test "by_clinical_case scope filters questions by clinical_case_id" do
    setup_for_scope_tests
    questions_in_cc_s1_c1 = Question.by_clinical_case(@cc_s1_c1.id)
    assert_includes questions_in_cc_s1_c1, @q_s_c1_cc1
    assert_not_includes questions_in_cc_s1_c1, @q_s_c1_cc2 # This is in a different CC (@cc_s2_c1)
    assert_equal 1, questions_in_cc_s1_c1.count
  end

  test "not_practiced_by scope returns questions not practiced by a given player" do
    setup_for_scope_tests
    # @player_s_test has practiced @q_s_c1_cc2.
    # @q_s_c1_cc1 and @q_s_c2_cc1 are not practiced by @player_s_test.
    not_practiced_list = Question.not_practiced_by(@player_s_test)

    assert_includes not_practiced_list, @q_s_c1_cc1, "@q_s_c1_cc1 should be in not_practiced_by list"
    assert_includes not_practiced_list, @q_s_c2_cc1, "@q_s_c2_cc1 should be in not_practiced_by list"
    assert_not_includes not_practiced_list, @q_s_c1_cc2, "@q_s_c1_cc2 (practiced) should NOT be in list"

    # Consider total questions vs. practiced for this player for a count check
    total_questions_in_scope_setup = 3 # We created 3 questions in setup_for_scope_tests
    practiced_by_player_count = @player_s_test.practiced_questions.count # Should be 1

    # This check is specific to the questions created *within setup_for_scope_tests*
    # If other questions exist from fixtures or other tests, this count might be off.
    # A more robust way might be to filter Question.all against those created in this setup.
    # For simplicity, assuming only these 3 are relevant for this player's "not practiced" status.
    # The `not_practiced_by` scope operates on `Question.where.not(id: player.practiced_questions.ids)`
    # So it considers ALL questions in the DB.

    expected_not_practiced_count = Question.count - practiced_by_player_count
    assert_equal expected_not_practiced_count, not_practiced_list.count
  end
end

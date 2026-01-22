require "test_helper"

class PlayerExamTest < ActiveSupport::TestCase
  fixtures :users, :categories, :exams, :exam_questions, :answers
  # Associations
  test "should belong to user" do
    ue = UserExam.new
    assert_respond_to ue, :user
    assert_respond_to ue, :user_id
  end

  test "should belong to exam" do
    ue = UserExam.new
    assert_respond_to ue, :exam
    assert_respond_to ue, :exam_id
  end

  test "should have many user_exam_answers" do
    ue = UserExam.new
    assert_respond_to ue, :user_exam_answers
    # Dependent destroy for user_exam_answers is not specified in model.
  end

  test "should have many exam_questions through exam" do
    ue = UserExam.new
    assert_respond_to ue, :exam_questions
  end

  # Validations
  test "should be invalid without a user" do
    user_exam = UserExam.new(exam: exams(:exam_one_urgencias))
    assert_not user_exam.valid?, "UserExam should be invalid without a user"
    assert_includes user_exam.errors[:user], "must exist"
  end

  test "should be invalid without an exam" do
    user_exam = UserExam.new(user: users(:player_one))
    assert_not user_exam.valid?, "UserExam should be invalid without an exam"
    assert_includes user_exam.errors[:exam], "must exist"
  end
  # No explicit uniqueness validation on (user, exam) in schema/model to test here.

  # General setup for tests that don't need isolated scope/method data
  setup do
    @player_one_fix = users(:player_one)
    @exam_one_fix = exams(:exam_one_urgencias) # Fixture: "Cardiology Basics"
    # exam_questions.yml links to @exam_one_fix:
    # eq_exam1_q1 (q: questions(:one), points: 10)
    # eq_exam1_q2 (q: questions(:two), points: 5)
    @eq1_for_exam1_fix = exam_questions(:eq_one_q_one)
    @eq2_for_exam1_fix = exam_questions(:eq_one_q_two)

    @ans_for_eq1_q_fix = answers(:one) # For questions(:one)
    @ans_for_eq2_q_fix = answers(:three) # For questions(:two)

    # Ensure fixture answer compatibility (important if fixtures are complex)
    if @ans_for_eq1_q_fix.question != @eq1_for_exam1_fix.question
      @ans_for_eq1_q_fix.update!(question: @eq1_for_exam1_fix.question)
    end
    if @ans_for_eq2_q_fix.question != @eq2_for_exam1_fix.question
      @ans_for_eq2_q_fix.update!(question: @eq2_for_exam1_fix.question)
    end
  end

  test "should be valid with a user and an exam" do
    user_exam = UserExam.new(user: @player_one_fix, exam: @exam_one_fix)
    assert user_exam.valid?, user_exam.errors.full_messages.join(", ")
  end

  test "optional attributes (started_at, completed_at, score, status) can be nil upon creation" do
    user_exam = UserExam.create!(user: @player_one_fix, exam: @exam_one_fix) # Save to DB
    user_exam.reload # Fetch from DB to check persisted state (nil for these fields)
    assert_nil user_exam.started_at
    assert_nil user_exam.completed_at
    assert_nil user_exam.score
    assert_nil user_exam.status # No default for status in schema, so should be nil
  end

  # Scopes
  def setup_for_scope_tests
    UserExam.delete_all # Clean slate for precise scope tests

    @user_s = User.create!(facebook_id: "fb_pe_scope_#{SecureRandom.hex(3)}", email: "scope@example.com", role: :player)
    @category = categories(:one)
    @exam_s1 = Exam.create!(name: "Scope Exam UE1", category: @category)
    @exam_s2 = Exam.create!(name: "Scope Exam UE2", category: @category)
    @exam_s3 = Exam.create!(name: "Scope Exam UE3", category: @category) # exams(:two) could also be used if distinct

    @ue_completed_scope = UserExam.create!(user: @user_s, exam: @exam_s1, status: "completed", score: 85, completed_at: 1.hour.ago)
    @ue_in_progress_scope = UserExam.create!(user: @user_s, exam: @exam_s2, status: "in_progress", started_at: 30.minutes.ago)
    @ue_pending_scope = UserExam.create!(user: @user_s, exam: @exam_s3, status: "pending")

    # Another completed for a different user to test scope isn't user-specific unless intended
    other_user_s = User.create!(facebook_id: "fb_pe_other_scope_#{SecureRandom.hex(3)}", email: "otherscope@example.com", role: :player)
    @ue_completed_other_user_scope = UserExam.create!(user: other_user_s, exam: @exam_s1, status: "completed", score: 90, completed_at: Time.now)
  end

  test "complete scope returns only completed user_exams" do
    setup_for_scope_tests
    completed_exams_from_scope = UserExam.complete

    assert_includes completed_exams_from_scope, @ue_completed_scope
    assert_includes completed_exams_from_scope, @ue_completed_other_user_scope
    assert_not_includes completed_exams_from_scope, @ue_in_progress_scope
    assert_not_includes completed_exams_from_scope, @ue_pending_scope
    assert_equal 2, completed_exams_from_scope.count
  end

  test "in_progress scope returns only in_progress user_exams" do
    # This test assumes the typo `la` in `scope :in_progress, -> { where(la "in_progress") }`
    # in the UserExam model has been corrected to `status: "in_progress"`.
    # If the typo persists, this test will likely fail or error.
    setup_for_scope_tests
    in_progress_exams_from_scope = UserExam.in_progress

    assert_includes in_progress_exams_from_scope, @ue_in_progress_scope
    assert_not_includes in_progress_exams_from_scope, @ue_completed_scope
    assert_not_includes in_progress_exams_from_scope, @ue_pending_scope
    assert_equal 1, in_progress_exams_from_scope.count
  end

  # Instance Method: calculate_score
  def setup_for_calculate_score_test
    @user_cs = User.create!(facebook_id: "fb_pe_cs_#{SecureRandom.hex(3)}", email: "cs@example.com", role: :player)
    # Use an exam with known ExamQuestions and points
    @exam_cs = exams(:exam_one_urgencias) # This exam has @eq1_for_exam1_fix (10 pts) and @eq2_for_exam1_fix (5 pts)
    @user_exam_for_calc_score = UserExam.create!(user: @user_cs, exam: @exam_cs)
  end

  test "#calculate_score sums points_earned from associated user_exam_answers" do
    setup_for_calculate_score_test

    # User answers EQ1, earns full points (10)
    UserExamAnswer.create!(
      user_exam: @user_exam_for_calc_score,
      exam_question: @eq1_for_exam1_fix, # Max points: 10
      answer: @ans_for_eq1_q_fix,     # Correct answer for its question
      points_earned: @eq1_for_exam1_fix.points
    )
    # User answers EQ2, earns partial points (e.g., 3 out of 5)
    UserExamAnswer.create!(
      user_exam: @user_exam_for_calc_score,
      exam_question: @eq2_for_exam1_fix, # Max points: 5
      answer: @ans_for_eq2_q_fix,     # Correct answer
      points_earned: 3
    )
    assert_equal 13, @user_exam_for_calc_score.calculate_score # Expected: 10 + 3
  end

  test "#calculate_score returns 0 if no user_exam_answers exist" do
    setup_for_calculate_score_test # Creates @user_exam_for_calc_score with no answers yet
    assert_equal 0, @user_exam_for_calc_score.calculate_score
  end

  test "#calculate_score returns 0 if user_exam_answers have nil points_earned" do
    setup_for_calculate_score_test
    UserExamAnswer.create!(
      user_exam: @user_exam_for_calc_score, exam_question: @eq1_for_exam1_fix,
      answer: @ans_for_eq1_q_fix, points_earned: nil
    )
    UserExamAnswer.create!(
      user_exam: @user_exam_for_calc_score, exam_question: @eq2_for_exam1_fix,
      answer: @ans_for_eq2_q_fix, points_earned: nil
    )
    assert_equal 0, @user_exam_for_calc_score.calculate_score # SQL SUM of NULLs is typically 0.
  end

  test "#calculate_score correctly sums if some points_earned are nil and others are not" do
    setup_for_calculate_score_test
    UserExamAnswer.create!(
      user_exam: @user_exam_for_calc_score, exam_question: @eq1_for_exam1_fix,
      answer: @ans_for_eq1_q_fix, points_earned: 7 # Earned 7 points
    )
    UserExamAnswer.create!(
      user_exam: @user_exam_for_calc_score, exam_question: @eq2_for_exam1_fix,
      answer: @ans_for_eq2_q_fix, points_earned: nil # Nil points for this one
    )
    assert_equal 7, @user_exam_for_calc_score.calculate_score
  end

  test "can access exam_questions through the associated exam" do
    user_exam = UserExam.create!(user: @player_one_fix, exam: @exam_one_fix)
    # @exam_one_fix (exams(:one)) is associated with @eq1_for_exam1_fix and @eq2_for_exam1_fix

    associated_eq_ids = user_exam.exam_questions.pluck(:id)
    assert_equal 2, associated_eq_ids.count, "Should have 2 exam questions from the associated exam"
    assert_includes associated_eq_ids, @eq1_for_exam1_fix.id
    assert_includes associated_eq_ids, @eq2_for_exam1_fix.id
  end

  # Note on the `in_progress` scope typo:
  # The test for the `in_progress` scope assumes the model's scope definition is corrected from `la "in_progress"` to `status: "in_progress"`.
  # If the model is not fixed, that specific scope test will fail.
end

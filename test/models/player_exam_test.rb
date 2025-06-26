require "test_helper"

class PlayerExamTest < ActiveSupport::TestCase
  fixtures :players, :exams, :exam_questions, :answers
  # Associations
  test "should belong to player" do
    pe = PlayerExam.new
    assert_respond_to pe, :player
    assert_respond_to pe, :player_id
  end

  test "should belong to exam" do
    pe = PlayerExam.new
    assert_respond_to pe, :exam
    assert_respond_to pe, :exam_id
  end

  test "should have many player_exam_answers" do
    pe = PlayerExam.new
    assert_respond_to pe, :player_exam_answers
    # Dependent destroy for player_exam_answers is not specified in model.
  end

  test "should have many exam_questions through exam" do
    pe = PlayerExam.new
    assert_respond_to pe, :exam_questions
  end

  # Validations
  test "should be invalid without a player" do
    player_exam = PlayerExam.new(exam: exams(:exam_one))
    assert_not player_exam.valid?, "PlayerExam should be invalid without a player"
    assert_includes player_exam.errors[:player], "must exist"
  end

  test "should be invalid without an exam" do
    player_exam = PlayerExam.new(player: players(:player_one))
    assert_not player_exam.valid?, "PlayerExam should be invalid without an exam"
    assert_includes player_exam.errors[:exam], "must exist"
  end
  # No explicit uniqueness validation on (player, exam) in schema/model to test here.

  # General setup for tests that don't need isolated scope/method data
  setup do
    @player_one_fix = players(:player_one)
    @exam_one_fix = exams(:exam_one) # Fixture: "Cardiology Basics"
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

  test "should be valid with a player and an exam" do
    player_exam = PlayerExam.new(player: @player_one_fix, exam: @exam_one_fix)
    assert player_exam.valid?, player_exam.errors.full_messages.join(", ")
  end

  test "optional attributes (started_at, completed_at, score, status) can be nil upon creation" do
    player_exam = PlayerExam.create!(player: @player_one_fix, exam: @exam_one_fix) # Save to DB
    player_exam.reload # Fetch from DB to check persisted state (nil for these fields)
    assert_nil player_exam.started_at
    assert_nil player_exam.completed_at
    assert_nil player_exam.score
    assert_nil player_exam.status # No default for status in schema, so should be nil
  end

  # Scopes
  def setup_for_scope_tests
    PlayerExam.delete_all # Clean slate for precise scope tests

    @player_s = Player.create!(facebook_id: "fb_pe_scope_#{SecureRandom.hex(3)}")
    @exam_s1 = Exam.create!(name: "Scope Exam PE1")
    @exam_s2 = Exam.create!(name: "Scope Exam PE2")
    @exam_s3 = Exam.create!(name: "Scope Exam PE3") # exams(:two) could also be used if distinct

    @pe_completed_scope = PlayerExam.create!(player: @player_s, exam: @exam_s1, status: "completed", score: 85, completed_at: 1.hour.ago)
    @pe_in_progress_scope = PlayerExam.create!(player: @player_s, exam: @exam_s2, status: "in_progress", started_at: 30.minutes.ago)
    @pe_pending_scope = PlayerExam.create!(player: @player_s, exam: @exam_s3, status: "pending")

    # Another completed for a different player to test scope isn't player-specific unless intended
    other_player_s = Player.create!(facebook_id: "fb_pe_other_scope_#{SecureRandom.hex(3)}")
    @pe_completed_other_player_scope = PlayerExam.create!(player: other_player_s, exam: @exam_s1, status: "completed", score: 90, completed_at: Time.now)
  end

  test "complete scope returns only completed player_exams" do
    setup_for_scope_tests
    completed_exams_from_scope = PlayerExam.complete

    assert_includes completed_exams_from_scope, @pe_completed_scope
    assert_includes completed_exams_from_scope, @pe_completed_other_player_scope
    assert_not_includes completed_exams_from_scope, @pe_in_progress_scope
    assert_not_includes completed_exams_from_scope, @pe_pending_scope
    assert_equal 2, completed_exams_from_scope.count
  end

  test "in_progress scope returns only in_progress player_exams" do
    # This test assumes the typo `la` in `scope :in_progress, -> { where(la "in_progress") }`
    # in the PlayerExam model has been corrected to `status: "in_progress"`.
    # If the typo persists, this test will likely fail or error.
    setup_for_scope_tests
    in_progress_exams_from_scope = PlayerExam.in_progress

    assert_includes in_progress_exams_from_scope, @pe_in_progress_scope
    assert_not_includes in_progress_exams_from_scope, @pe_completed_scope
    assert_not_includes in_progress_exams_from_scope, @pe_pending_scope
    assert_equal 1, in_progress_exams_from_scope.count
  end

  # Instance Method: calculate_score
  def setup_for_calculate_score_test
    @player_cs = Player.create!(facebook_id: "fb_pe_cs_#{SecureRandom.hex(3)}")
    # Use an exam with known ExamQuestions and points
    @exam_cs = exams(:exam_one) # This exam has @eq1_for_exam1_fix (10 pts) and @eq2_for_exam1_fix (5 pts)
    @player_exam_for_calc_score = PlayerExam.create!(player: @player_cs, exam: @exam_cs)
  end

  test "#calculate_score sums points_earned from associated player_exam_answers" do
    setup_for_calculate_score_test

    # Player answers EQ1, earns full points (10)
    PlayerExamAnswer.create!(
      player_exam: @player_exam_for_calc_score,
      exam_question: @eq1_for_exam1_fix, # Max points: 10
      answer: @ans_for_eq1_q_fix,     # Correct answer for its question
      points_earned: @eq1_for_exam1_fix.points
    )
    # Player answers EQ2, earns partial points (e.g., 3 out of 5)
    PlayerExamAnswer.create!(
      player_exam: @player_exam_for_calc_score,
      exam_question: @eq2_for_exam1_fix, # Max points: 5
      answer: @ans_for_eq2_q_fix,     # Correct answer
      points_earned: 3
    )
    assert_equal 13, @player_exam_for_calc_score.calculate_score # Expected: 10 + 3
  end

  test "#calculate_score returns 0 if no player_exam_answers exist" do
    setup_for_calculate_score_test # Creates @player_exam_for_calc_score with no answers yet
    assert_equal 0, @player_exam_for_calc_score.calculate_score
  end

  test "#calculate_score returns 0 if player_exam_answers have nil points_earned" do
    setup_for_calculate_score_test
    PlayerExamAnswer.create!(
      player_exam: @player_exam_for_calc_score, exam_question: @eq1_for_exam1_fix,
      answer: @ans_for_eq1_q_fix, points_earned: nil
    )
    PlayerExamAnswer.create!(
      player_exam: @player_exam_for_calc_score, exam_question: @eq2_for_exam1_fix,
      answer: @ans_for_eq2_q_fix, points_earned: nil
    )
    assert_equal 0, @player_exam_for_calc_score.calculate_score # SQL SUM of NULLs is typically 0.
  end

  test "#calculate_score correctly sums if some points_earned are nil and others are not" do
    setup_for_calculate_score_test
    PlayerExamAnswer.create!(
      player_exam: @player_exam_for_calc_score, exam_question: @eq1_for_exam1_fix,
      answer: @ans_for_eq1_q_fix, points_earned: 7 # Earned 7 points
    )
    PlayerExamAnswer.create!(
      player_exam: @player_exam_for_calc_score, exam_question: @eq2_for_exam1_fix,
      answer: @ans_for_eq2_q_fix, points_earned: nil # Nil points for this one
    )
    assert_equal 7, @player_exam_for_calc_score.calculate_score
  end

  test "can access exam_questions through the associated exam" do
    player_exam = PlayerExam.create!(player: @player_one_fix, exam: @exam_one_fix)
    # @exam_one_fix (exams(:one)) is associated with @eq1_for_exam1_fix and @eq2_for_exam1_fix

    associated_eq_ids = player_exam.exam_questions.pluck(:id)
    assert_equal 2, associated_eq_ids.count, "Should have 2 exam questions from the associated exam"
    assert_includes associated_eq_ids, @eq1_for_exam1_fix.id
    assert_includes associated_eq_ids, @eq2_for_exam1_fix.id
  end

  # Note on the `in_progress` scope typo:
  # The test for the `in_progress` scope assumes the model's scope definition is corrected from `la "in_progress"` to `status: "in_progress"`.
  # If the model is not fixed, that specific scope test will fail.
end

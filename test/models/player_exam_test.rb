require "test_helper"

class PlayerExamTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:player)
    should belong_to(:exam)
    should have_many(:player_exam_answers)
    should have_many(:exam_questions).through(:exam)
  end

  context "validations" do
    should "be invalid without a player" do
      pe = PlayerExam.new(exam: exams(:one))
      assert_not pe.valid?
      assert_includes pe.errors[:player], "must exist"
    end

    should "be invalid without an exam" do
      pe = PlayerExam.new(player: players(:player_one))
      assert_not pe.valid?
      assert_includes pe.errors[:exam], "must exist"
    end
    # No explicit uniqueness validation on (player, exam) in model/schema.
  end

  setup do
    @player = players(:player_one)
    @exam = exams(:one) # exams(:one) has name "Cardiology Basics"
    # exam_questions.yml defines:
    # eq_exam1_q1: exam: one, question: one (Cardio Q1), position: 1, points: 10
    # eq_exam1_q2: exam: one, question: two (Cardio Q2), position: 2, points: 5
    @exam_question1_for_exam1 = exam_questions(:eq_exam1_q1)
    @exam_question2_for_exam1 = exam_questions(:eq_exam1_q2)

    # Answers for these questions
    # answers.yml:
    # one: question: one (Cardio Q1), description: "IECA o ARA II", is_correct: true
    # three: question: two (Cardio Q2), description: "Poliuria", is_correct: true
    @answer_for_eq1_question = answers(:one)
    @answer_for_eq2_question = answers(:three)

    # Ensure fixture associations align, especially if answers might belong to other questions by default
    @answer_for_eq1_question.update!(question: @exam_question1_for_exam1.question) if @answer_for_eq1_question.question != @exam_question1_for_exam1.question
    @answer_for_eq2_question.update!(question: @exam_question2_for_exam1.question) if @answer_for_eq2_question.question != @exam_question2_for_exam1.question
  end

  test "should be valid with a player and an exam" do
    player_exam = PlayerExam.new(player: @player, exam: @exam)
    assert player_exam.valid?, player_exam.errors.full_messages.join(", ")
  end

  test "optional attributes (started_at, completed_at, score, status) can be nil" do
    player_exam = PlayerExam.create!(player: @player, exam: @exam) # Save to DB
    player_exam.reload
    assert_nil player_exam.started_at
    assert_nil player_exam.completed_at
    assert_nil player_exam.score
    assert_nil player_exam.status # No default for status in schema
  end

  context "scopes" do
    setup do
      PlayerExam.delete_all # Clean slate for scope tests

      @exam2_for_scopes = Exam.create!(name: "Scope Exam 2")
      @exam3_for_scopes = exams(:two) # Another exam from fixtures, e.g., "Neurology Basics"


      @pe_completed = PlayerExam.create!(player: @player, exam: @exam, status: "completed", score: 80, completed_at: Time.now)
      @pe_in_progress = PlayerExam.create!(player: @player, exam: @exam2_for_scopes, status: "in_progress", started_at: Time.now)
      @pe_pending = PlayerExam.create!(player: @player, exam: @exam3_for_scopes, status: "pending")
      # Another completed for count check
      other_player = Player.create!(facebook_id: "fb_other_scope_#{SecureRandom.hex(3)}")
      @pe_completed_other_player = PlayerExam.create!(player: other_player, exam: @exam, status: "completed", score: 90)
    end

    should "return only completed player_exams for :complete scope" do
      completed_exams_scope = PlayerExam.complete
      assert_includes completed_exams_scope, @pe_completed
      assert_includes completed_exams_scope, @pe_completed_other_player
      assert_not_includes completed_exams_scope, @pe_in_progress
      assert_not_includes completed_exams_scope, @pe_pending
      assert_equal 2, completed_exams_scope.count
    end

    should "return only in_progress player_exams for :in_progress scope" do
      # Assuming the typo 'la' in `scope :in_progress, -> { where(la "in_progress") }`
      # is fixed in the model to `scope :in_progress, -> { where(status: "in_progress") }`
      # If not fixed, this test will fail or error out.
      in_progress_exams_scope = PlayerExam.in_progress
      assert_includes in_progress_exams_scope, @pe_in_progress
      assert_not_includes in_progress_exams_scope, @pe_completed
      assert_not_includes in_progress_exams_scope, @pe_pending
      assert_equal 1, in_progress_exams_scope.count
    end
  end

  context "#calculate_score" do
    setup do
      # A fresh PlayerExam for this context
      @player_exam_for_calc_score = PlayerExam.create!(player: @player, exam: @exam)
      # @exam (exams(:one)) has @exam_question1_for_exam1 (points: 10) and @exam_question2_for_exam1 (points: 5)
    end

    should "sum points_earned from associated player_exam_answers" do
      PlayerExamAnswer.create!(
        player_exam: @player_exam_for_calc_score,
        exam_question: @exam_question1_for_exam1, # Max points: 10
        answer: @answer_for_eq1_question, # Correct answer for its question
        is_correct: true, # This should be set by PlayerExamAnswer model based on Answer
        points_earned: @exam_question1_for_exam1.points # Earned full 10 points
      )
      PlayerExamAnswer.create!(
        player_exam: @player_exam_for_calc_score,
        exam_question: @exam_question2_for_exam1, # Max points: 5
        answer: @answer_for_eq2_question, # Correct answer
        is_correct: true,
        points_earned: 3 # Earned partial 3 points
      )
      assert_equal 13, @player_exam_for_calc_score.calculate_score # 10 + 3
    end

    should "return 0 if no player_exam_answers exist" do
      assert_equal 0, @player_exam_for_calc_score.calculate_score # No P.E.Answers yet
    end

    should "return 0 if player_exam_answers have nil points_earned" do
      PlayerExamAnswer.create!(
        player_exam: @player_exam_for_calc_score, exam_question: @exam_question1_for_exam1,
        answer: @answer_for_eq1_question, points_earned: nil
      )
      PlayerExamAnswer.create!(
        player_exam: @player_exam_for_calc_score, exam_question: @exam_question2_for_exam1,
        answer: @answer_for_eq2_question, points_earned: nil
      )
      assert_equal 0, @player_exam_for_calc_score.calculate_score # SUM of NULLs is 0
    end

     should "correctly sum if some points_earned are nil and some are not" do
      PlayerExamAnswer.create!(
        player_exam: @player_exam_for_calc_score, exam_question: @exam_question1_for_exam1,
        answer: @answer_for_eq1_question, points_earned: 7
      )
      PlayerExamAnswer.create!(
        player_exam: @player_exam_for_calc_score, exam_question: @exam_question2_for_exam1,
        answer: @answer_for_eq2_question, points_earned: nil
      )
      assert_equal 7, @player_exam_for_calc_score.calculate_score
    end
  end

  test "can access exam_questions through the associated exam" do
    player_exam = PlayerExam.create!(player: @player, exam: @exam)

    # @exam (exams(:one)) is associated with exam_questions :eq_exam1_q1 and :eq_exam1_q2
    # These have questions :one and :two respectively.
    assert_equal 2, player_exam.exam_questions.count, "Should have 2 exam questions from the associated exam"
    assert_includes player_exam.exam_questions.map(&:id), @exam_question1_for_exam1.id
    assert_includes player_exam.exam_questions.map(&:id), @exam_question2_for_exam1.id
  end

  # Note on the `in_progress` scope typo:
  # The test `PlayerExamTest#test_in_progress_scope_has_a_typo_la_instead_of_status`
  # was removed as it's better to assume the model will be fixed.
  # The `scopes` context above now tests the corrected behavior.
  # If the model remains unfixed, the `PlayerExam.in_progress` scope test will fail.
end

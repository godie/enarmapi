require "test_helper"

class PlayerExamAnswerTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:player_exam)
    should belong_to(:exam_question)
    should belong_to(:answer)
  end

  context "validations" do
    setup do
      @player_exam_for_val = player_exams(:one)
      @exam_question_for_val = exam_questions(:eq_exam1_q1)
      @answer_for_val = answers(:one)

      @answer_for_val.update!(question: @exam_question_for_val.question) if @answer_for_val.question != @exam_question_for_val.question

      # Create a record to test uniqueness against
      PlayerExamAnswer.find_or_create_by!(
        player_exam: @player_exam_for_val,
        exam_question: @exam_question_for_val
      ) do |pea|
        pea.answer = @answer_for_val # Assign answer only on creation
      end
    end

    subject do
      # For shoulda-matchers, subject should be a new, valid record that could potentially conflict.
      # Use a *different* ExamQuestion initially for the subject to be valid on its own.
      # The test for uniqueness will then try to set exam_question_id to one that causes conflict.
      eq_other = exam_questions(:eq_exam1_q2) # Different ExamQuestion from the same Exam as @player_exam_for_val
      ans_other = answers(:three) # Corresponding answer for eq_other.question
      ans_other.update!(question: eq_other.question) if ans_other.question != eq_other.question

      PlayerExamAnswer.new(
        player_exam: @player_exam_for_val,
        exam_question: eq_other,
        answer: ans_other
      )
    end
    # Test uniqueness of (player_exam_id, exam_question_id)
    should validate_uniqueness_of(:exam_question_id).scoped_to(:player_exam_id).with_message("has already been taken")

    test "manual uniqueness validation for (player_exam_id, exam_question_id)" do
      # The record for @player_exam_for_val and @exam_question_for_val is created in setup.
      # Try to create another one with a different answer.
      answer_alt = Answer.create!(question: @exam_question_for_val.question, text: "Alt answer", is_correct: false)
      duplicate_pea = PlayerExamAnswer.new(
        player_exam: @player_exam_for_val,
        exam_question: @exam_question_for_val, # Same player_exam and exam_question
        answer: answer_alt # Different answer, but should still fail uniqueness on (player_exam, exam_question)
      )
      assert_not duplicate_pea.valid?, "Should be invalid due to uniqueness constraint on (player_exam_id, exam_question_id)"
      assert_includes duplicate_pea.errors[:exam_question_id], "has already been taken"
    end

    should "be invalid without a player_exam" do
      pea = PlayerExamAnswer.new(exam_question: @exam_question_for_val, answer: @answer_for_val)
      assert_not pea.valid?
      assert_includes pea.errors[:player_exam], "must exist"
    end

    should "be invalid without an exam_question" do
      pea = PlayerExamAnswer.new(player_exam: @player_exam_for_val, answer: @answer_for_val)
      assert_not pea.valid?
      assert_includes pea.errors[:exam_question], "must exist"
    end

    should "be invalid without an answer" do
      pea = PlayerExamAnswer.new(player_exam: @player_exam_for_val, exam_question: @exam_question_for_val)
      assert_not pea.valid?
      assert_includes pea.errors[:answer], "must exist"
    end
  end

  setup do
    # General setup for other tests, ensure fresh objects or use specific ones.
    @player_exam = player_exams(:one) # player_one on exam_one
    @eq1_exam1 = exam_questions(:eq_exam1_q1) # exam_one, question_one, points 10
    @ans_q1_correct = answers(:one) # for question_one, is_correct: true
    @ans_q1_incorrect = answers(:two) # for question_one, is_correct: false

    # Ensure answers are compatible with the question in @eq1_exam1
    @ans_q1_correct.update!(question: @eq1_exam1.question) if @ans_q1_correct.question != @eq1_exam1.question
    @ans_q1_incorrect.update!(question: @eq1_exam1.question) if @ans_q1_incorrect.question != @eq1_exam1.question

    # A second exam question from the same exam for variety
    @eq2_exam1 = exam_questions(:eq_exam1_q2) # exam_one, question_two, points 5
    @ans_q2_correct = answers(:three) # for question_two, is_correct: true
    @ans_q2_correct.update!(question: @eq2_exam1.question) if @ans_q2_correct.question != @eq2_exam1.question
  end

  test "should be valid with all required associations" do
    # Use @eq2_exam1 for @player_exam as @eq1_exam1 might have been used in validation setup for this PE
    pea = PlayerExamAnswer.new(
      player_exam: @player_exam,
      exam_question: @eq2_exam1,
      answer: @ans_q2_correct
    )
    assert pea.valid?, pea.errors.full_messages.join(", ")
  end

  test "attributes is_correct and points_earned can be nil upon creation" do
    # Use a unique PlayerExam and ExamQuestion combination for this test
    pe_new = PlayerExam.create!(player: players(:player_two), exam: exams(:two))
    eq_new = ExamQuestion.create!(exam: exams(:two), question: questions(:three), points: 5)
    ans_new = Answer.create!(question: questions(:three), text: "New Ans PEA", is_correct: true)

    pea = PlayerExamAnswer.new(
      player_exam: pe_new,
      exam_question: eq_new,
      answer: ans_new,
      is_correct: nil, # Explicitly nil
      points_earned: nil # Explicitly nil
    )
    assert pea.valid?, "PEA should be valid with nil is_correct and points_earned. Errors: #{pea.errors.full_messages.join(", ")}"
    assert pea.save
    pea.reload
    assert_nil pea.is_correct
    assert_nil pea.points_earned
  end

  # PlayerExamAnswer model does not have callbacks like set_correctness or calculate_points_earned.
  # These attributes are expected to be set directly.

  test "is_correct can be set to true or false" do
    pea_true = PlayerExamAnswer.create!(
      player_exam: @player_exam, exam_question: @eq2_exam1, answer: @ans_q2_correct, is_correct: true
    )
    assert_equal true, pea_true.reload.is_correct

    # Need another unique (PlayerExam, ExamQuestion) pair for the false case, or different PlayerExam/ExamQuestion.
    pe_other = PlayerExam.create!(player: players(:player_two), exam: @player_exam.exam) # Different player, same exam
    eq_other_for_pe_other = @eq1_exam1 # Can use the same exam_question for a different player_exam

    pea_false = PlayerExamAnswer.create!(
      player_exam: pe_other, exam_question: eq_other_for_pe_other, answer: @ans_q1_incorrect, is_correct: false
    )
    assert_equal false, pea_false.reload.is_correct
  end

  test "points_earned can be assigned a value" do
    pea = PlayerExamAnswer.create!(
      player_exam: @player_exam, exam_question: @eq2_exam1, # Using eq2 as eq1 might be used by validation setup
      answer: @ans_q2_correct,
      points_earned: @eq2_exam1.points # Assign full points for the exam_question
    )
    assert_equal @eq2_exam1.points, pea.reload.points_earned
  end

  test "destroying PlayerExamAnswer does not destroy its associations" do
    # Create a PEA specifically for this test to destroy
    pea_to_delete = PlayerExamAnswer.create!(
      player_exam: @player_exam, exam_question: @eq2_exam1, answer: @ans_q2_correct
    )
    # Capture IDs before deletion
    player_exam_id = pea_to_delete.player_exam_id
    exam_question_id = pea_to_delete.exam_question_id
    answer_id = pea_to_delete.answer_id

    pea_to_delete.destroy

    assert_raises(ActiveRecord::RecordNotFound) { PlayerExamAnswer.find(pea_to_delete.id) }
    assert PlayerExam.exists?(player_exam_id), "Associated PlayerExam should not be destroyed."
    assert ExamQuestion.exists?(exam_question_id), "Associated ExamQuestion should not be destroyed."
    assert Answer.exists?(answer_id), "Associated Answer should not be destroyed."
  end
end

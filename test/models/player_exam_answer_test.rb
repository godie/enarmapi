require "test_helper"

class PlayerExamAnswerTest < ActiveSupport::TestCase
  # Associations
  test "should belong to player_exam" do
    pea = PlayerExamAnswer.new
    assert_respond_to pea, :player_exam
    assert_respond_to pea, :player_exam_id
  end

  test "should belong to exam_question" do
    pea = PlayerExamAnswer.new
    assert_respond_to pea, :exam_question
    assert_respond_to pea, :exam_question_id
  end

  test "should belong to answer" do
    pea = PlayerExamAnswer.new
    assert_respond_to pea, :answer
    assert_respond_to pea, :answer_id
  end

  # Validations
  setup do
    # For uniqueness validation (player_exam_id, exam_question_id) and general tests
    @player_exam_one = player_exams(:one) # Fixture: player_one on exam_one
    @eq1_exam1 = exam_questions(:eq_exam1_q1) # Fixture: for exam_one & question_one
    @answer_for_eq1 = answers(:one) # Fixture: for question_one (which is @eq1_exam1.question)

    # Ensure answer is compatible with the exam_question's question
    if @answer_for_eq1.question != @eq1_exam1.question
      @answer_for_eq1.update!(question: @eq1_exam1.question)
    end

    # Create an existing PlayerExamAnswer for uniqueness testing
    PlayerExamAnswer.find_or_create_by!(
      player_exam: @player_exam_one,
      exam_question: @eq1_exam1
    ) do |pea_setup|
      pea_setup.answer = @answer_for_eq1 # Assign answer only if creating new
    end

    # Other fixtures for varied tests
    @eq2_exam1 = exam_questions(:eq_exam1_q2) # Fixture: for exam_one & question_two
    @answer_for_eq2 = answers(:three) # Fixture: for question_two (which is @eq2_exam1.question)
    if @answer_for_eq2.question != @eq2_exam1.question
      @answer_for_eq2.update!(question: @eq2_exam1.question)
    end
  end

  test "should be invalid without a player_exam" do
    pea = PlayerExamAnswer.new(exam_question: @eq1_exam1, answer: @answer_for_eq1)
    assert_not pea.valid?, "PlayerExamAnswer should be invalid without a player_exam"
    assert_includes pea.errors[:player_exam], "must exist"
  end

  test "should be invalid without an exam_question" do
    pea = PlayerExamAnswer.new(player_exam: @player_exam_one, answer: @answer_for_eq1)
    assert_not pea.valid?, "PlayerExamAnswer should be invalid without an exam_question"
    assert_includes pea.errors[:exam_question], "must exist"
  end

  test "should be invalid without an answer" do
    pea = PlayerExamAnswer.new(player_exam: @player_exam_one, exam_question: @eq1_exam1)
    assert_not pea.valid?, "PlayerExamAnswer should be invalid without an answer"
    assert_includes pea.errors[:answer], "must exist"
  end

  test "exam_question_id must be unique per player_exam_id" do
    # A PlayerExamAnswer for @player_exam_one and @eq1_exam1 was created in setup.
    # Try to create another one with a different answer for the same player_exam and exam_question.
    alternative_answer_for_eq1 = Answer.create!(question: @eq1_exam1.question, text: "Alternative Answer Text", is_correct: false)

    duplicate_pea = PlayerExamAnswer.new(
      player_exam: @player_exam_one,
      exam_question: @eq1_exam1, # Same player_exam and exam_question
      answer: alternative_answer_for_eq1
    )
    assert_not duplicate_pea.valid?, "Should be invalid due to (player_exam_id, exam_question_id) uniqueness"
    # Default uniqueness error message is "has already been taken", applied to the attribute being validated.
    assert_includes duplicate_pea.errors[:exam_question_id], "has already been taken"
  end

  # General attributes and validity
  test "should be valid with all required associations" do
    # Use @eq2_exam1 for @player_exam_one as @eq1_exam1 is used in uniqueness setup for this PEA.
    pea = PlayerExamAnswer.new(
      player_exam: @player_exam_one,
      exam_question: @eq2_exam1, # Different ExamQuestion for the same PlayerExam
      answer: @answer_for_eq2    # Corresponding answer
    )
    assert pea.valid?, pea.errors.full_messages.join(", ")
  end

  test "attributes is_correct and points_earned can be nil upon creation" do
    # Use a completely new set of PlayerExam, ExamQuestion, Answer to ensure no conflicts.
    player_new = Player.create!(facebook_id: "fb_pea_nilattr_#{SecureRandom.hex(3)}")
    exam_new = Exam.create!(name: "PEA Nil Attr Exam")
    pe_new = PlayerExam.create!(player: player_new, exam: exam_new)

    question_new = Question.create!(text: "PEA Nil Attr Q", clinical_case: clinical_cases(:one))
    eq_new = ExamQuestion.create!(exam: exam_new, question: question_new, points: 10)
    ans_new = Answer.create!(question: question_new, text: "PEA Nil Attr Ans", is_correct: true)

    pea = PlayerExamAnswer.new(
      player_exam: pe_new,
      exam_question: eq_new,
      answer: ans_new,
      is_correct: nil,    # Explicitly set to nil
      points_earned: nil  # Explicitly set to nil
    )
    assert pea.valid?, "PEA should be valid with nil is_correct and points_earned. Errors: #{pea.errors.full_messages.join(", ")}"
    assert pea.save
    pea.reload
    assert_nil pea.is_correct
    assert_nil pea.points_earned
  end

  # PlayerExamAnswer model does not have callbacks like set_correctness or calculate_points_earned.
  # These attributes are expected to be set directly when the PEA record is created or updated.
  test "is_correct attribute can be set to true or false" do
    # Use @player_exam_one with @eq2_exam1 as this combo is not used in setup's find_or_create_by
    pea_true = PlayerExamAnswer.create!(
      player_exam: @player_exam_one, exam_question: @eq2_exam1, answer: @answer_for_eq2, is_correct: true
    )
    assert_equal true, pea_true.reload.is_correct

    # For the 'false' case, need a different PEA or ensure this one is destroyed first if re-using combo.
    # Let's use a different PlayerExam to be safe and clear.
    player2 = players(:player_two)
    pe_for_player2 = PlayerExam.create!(player: player2, exam: @player_exam_one.exam) # Same exam, different player

    # We can use @eq1_exam1 again for this different PlayerExam (pe_for_player2)
    answer_incorrect_for_eq1 = answers(:two) # This is for question_one (eq1_exam1.question) and is_correct: false
    if answer_incorrect_for_eq1.question != @eq1_exam1.question || answer_incorrect_for_eq1.is_correct == true
        answer_incorrect_for_eq1.update!(question: @eq1_exam1.question, is_correct: false)
    end

    pea_false = PlayerExamAnswer.create!(
      player_exam: pe_for_player2, exam_question: @eq1_exam1, answer: answer_incorrect_for_eq1, is_correct: false
    )
    assert_equal false, pea_false.reload.is_correct
  end

  test "points_earned attribute can be assigned a value" do
    # Use @player_exam_one and @eq2_exam1
    pea = PlayerExamAnswer.create!(
      player_exam: @player_exam_one,
      exam_question: @eq2_exam1,
      answer: @answer_for_eq2,
      points_earned: @eq2_exam1.points # Assign full points for this exam_question
    )
    assert_equal @eq2_exam1.points, pea.reload.points_earned

    # Test with a different value
    pea.update!(points_earned: 3)
    assert_equal 3, pea.reload.points_earned
  end

  test "destroying PlayerExamAnswer does not destroy its associated records (PlayerExam, ExamQuestion, Answer)" do
    # Create a PEA specifically for this deletion test to avoid fixture interference.
    # Use @player_exam_one and @eq2_exam1 as this pair is not created in global setup.
    pea_to_be_deleted = PlayerExamAnswer.create!(
      player_exam: @player_exam_one,
      exam_question: @eq2_exam1,
      answer: @answer_for_eq2
    )
    # Capture IDs before deletion to verify existence of associated records later.
    player_exam_id_val = pea_to_be_deleted.player_exam_id
    exam_question_id_val = pea_to_be_deleted.exam_question_id
    answer_id_val = pea_to_be_deleted.answer_id

    pea_to_be_deleted.destroy

    assert_raises(ActiveRecord::RecordNotFound) { PlayerExamAnswer.find(pea_to_be_deleted.id) }, "PlayerExamAnswer should be deleted."
    assert PlayerExam.exists?(player_exam_id_val), "Associated PlayerExam should NOT be destroyed."
    assert ExamQuestion.exists?(exam_question_id_val), "Associated ExamQuestion should NOT be destroyed."
    assert Answer.exists?(answer_id_val), "Associated Answer should NOT be destroyed."
  end
end

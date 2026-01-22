require "test_helper"

class PlayerExamAnswerTest < ActiveSupport::TestCase
  fixtures :categories, :exams, :users, :clinical_cases, :questions, :answers, :user_exams, :exam_questions
  # Associations
  test "should belong to user_exam" do
    uea = UserExamAnswer.new
    assert_respond_to uea, :user_exam
    assert_respond_to uea, :user_exam_id
  end

  test "should belong to exam_question" do
    uea = UserExamAnswer.new
    assert_respond_to uea, :exam_question
    assert_respond_to uea, :exam_question_id
  end

  test "should belong to answer" do
    uea = UserExamAnswer.new
    assert_respond_to uea, :answer
    assert_respond_to uea, :answer_id
  end

  # Validations
  setup do
    # For uniqueness validation (user_exam_id, exam_question_id) and general tests
    @user_exam_one = user_exams(:pe_one_exam_urgencias) # Fixture: player_one on exam_one
    @eq1_exam1 = exam_questions(:eq_one_q_one) # Fixture: for exam_one & question_one
    @answer_for_eq1 = answers(:one) # Fixture: for question_one (which is @eq1_exam1.question)
    @category = categories(:one)

    # Ensure answer is compatible with the exam_question's question
    if @answer_for_eq1.question != @eq1_exam1.question
      @answer_for_eq1.update!(question: @eq1_exam1.question)
    end

    # Create an existing UserExamAnswer for uniqueness testing
    UserExamAnswer.find_or_create_by!(
      user_exam: @user_exam_one,
      exam_question: @eq1_exam1
    ) do |uea_setup|
      uea_setup.answer = @answer_for_eq1 # Assign answer only if creating new
    end

    # Other fixtures for varied tests
    @eq2_exam1 = exam_questions(:eq_one_q_two) # Fixture: for exam_one & question_two
    @answer_for_eq2 = answers(:three) # Fixture: for question_two (which is @eq2_exam1.question)
    if @answer_for_eq2.question != @eq2_exam1.question
      @answer_for_eq2.update!(question: @eq2_exam1.question)
    end
  end

  test "should be invalid without a user_exam" do
    uea = UserExamAnswer.new(exam_question: @eq1_exam1, answer: @answer_for_eq1)
    assert_not uea.valid?, "UserExamAnswer should be invalid without a user_exam"
    assert_includes uea.errors[:user_exam], "must exist"
  end

  test "should be invalid without an exam_question" do
    uea = UserExamAnswer.new(user_exam: @user_exam_one, answer: @answer_for_eq1)
    assert_not uea.valid?, "UserExamAnswer should be invalid without an exam_question"
    assert_includes uea.errors[:exam_question], "must exist"
  end

  test "should be invalid without an answer" do
    uea = UserExamAnswer.new(user_exam: @user_exam_one, exam_question: @eq1_exam1)
    assert_not uea.valid?, "UserExamAnswer should be invalid without an answer"
    assert_includes uea.errors[:answer], "must exist"
  end

  test "exam_question_id must be unique per user_exam_id" do
    # A UserExamAnswer for @user_exam_one and @eq1_exam1 was created in setup.
    # Try to create another one with a different answer for the same user_exam and exam_question.
    alternative_answer_for_eq1 = Answer.create!(question: @eq1_exam1.question, text: "Alternative Answer Text", is_correct: false)

    duplicate_uea = UserExamAnswer.new(
      user_exam: @user_exam_one,
      exam_question: @eq1_exam1, # Same user_exam and exam_question
      answer: alternative_answer_for_eq1
    )
    assert_not duplicate_uea.valid?, "Should be invalid due to (user_exam_id, exam_question_id) uniqueness"
    # Default uniqueness error message is "has already been taken", applied to the attribute being validated.
    assert_includes duplicate_uea.errors[:exam_question_id], "ya ha sido respondida en este examen"
  end

  # General attributes and validity
  test "should be valid with all required associations" do
    # Use @eq2_exam1 for @user_exam_one as @eq1_exam1 is used in uniqueness setup for this UEA.
    uea = UserExamAnswer.new(
      user_exam: @user_exam_one,
      exam_question: @eq2_exam1, # Different ExamQuestion for the same UserExam
      answer: @answer_for_eq2    # Corresponding answer
    )
    assert uea.valid?, uea.errors.full_messages.join(", ")
  end

  test "attributes is_correct and points_earned can be nil upon creation" do
    # Use a completely new set of UserExam, ExamQuestion, Answer to ensure no conflicts.
    user_new = User.create!(facebook_id: "fb_pea_nilattr_#{SecureRandom.hex(3)}", email: "nilattr@example.com", role: :player)
    exam_new = Exam.create!(name: "UEA Nil Attr Exam", category: @category)
    ue_new = UserExam.create!(user: user_new, exam: exam_new)

    question_new = Question.create!(text: "UEA Nil Attr Q", clinical_case: clinical_cases(:one))
    eq_new = ExamQuestion.create!(exam: exam_new, question: question_new, points: 10)
    ans_new = Answer.create!(question: question_new, text: "UEA Nil Attr Ans", is_correct: true)

    uea = UserExamAnswer.new(
      user_exam: ue_new,
      exam_question: eq_new,
      answer: ans_new,
      is_correct: nil,    # Explicitly set to nil
      points_earned: nil  # Explicitly set to nil
    )
    assert uea.valid?, "UEA should be valid with nil is_correct and points_earned. Errors: #{uea.errors.full_messages.join(", ")}"
    assert uea.save
    uea.reload
    assert_nil uea.is_correct
    assert_nil uea.points_earned
  end

  # UserExamAnswer model does not have callbacks like set_correctness or calculate_points_earned.
  # These attributes are expected to be set directly when the UEA record is created or updated.
  test "is_correct attribute can be set to true or false" do
    # Use @user_exam_one with @eq2_exam1 as this combo is not used in setup's find_or_create_by
    uea_true = UserExamAnswer.create!(
      user_exam: @user_exam_one, exam_question: @eq2_exam1, answer: @answer_for_eq2, is_correct: true
    )
    assert_equal true, uea_true.reload.is_correct

    # For the 'false' case, need a different UEA or ensure this one is destroyed first if re-using combo.
    # Let's use a different UserExam to be safe and clear.
    user2 = users(:player_two)
    ue_for_user2 = UserExam.create!(user: user2, exam: @user_exam_one.exam) # Same exam, different user

    # We can use @eq1_exam1 again for this different UserExam (ue_for_user2)
    answer_incorrect_for_eq1 = answers(:two) # This is for question_one (eq1_exam1.question) and is_correct: false
    if answer_incorrect_for_eq1.question != @eq1_exam1.question || answer_incorrect_for_eq1.is_correct == true
        answer_incorrect_for_eq1.update!(question: @eq1_exam1.question, is_correct: false)
    end

    uea_false = UserExamAnswer.create!(
      user_exam: ue_for_user2, exam_question: @eq1_exam1, answer: answer_incorrect_for_eq1, is_correct: false
    )
    assert_equal false, uea_false.reload.is_correct
  end

  test "points_earned attribute can be assigned a value" do
    # Use @user_exam_one and @eq2_exam1
    uea = UserExamAnswer.create!(
      user_exam: @user_exam_one,
      exam_question: @eq2_exam1,
      answer: @answer_for_eq2,
      points_earned: @eq2_exam1.points # Assign full points for this exam_question
    )
    assert_equal @eq2_exam1.points, uea.reload.points_earned

    # Test with a different value
    uea.update!(points_earned: 3)
    assert_equal 3, uea.reload.points_earned
  end

  test "destroying UserExamAnswer does not destroy its associated records (UserExam, ExamQuestion, Answer)" do
    # Create a UEA specifically for this deletion test to avoid fixture interference.
    # Use @user_exam_one and @eq2_exam1 as this pair is not created in global setup.
    uea_to_be_deleted = UserExamAnswer.create!(
      user_exam: @user_exam_one,
      exam_question: @eq2_exam1,
      answer: @answer_for_eq2
    )
    # Capture IDs before deletion to verify existence of associated records later.
    user_exam_id_val = uea_to_be_deleted.user_exam_id
    exam_question_id_val = uea_to_be_deleted.exam_question_id
    answer_id_val = uea_to_be_deleted.answer_id

    uea_to_be_deleted.destroy

    # assert_raises(ActiveRecord::RecordNotFound) { UserExamAnswer.find(uea_to_be_deleted.id) }, "UserExamAnswer should be deleted."
    assert UserExam.exists?(user_exam_id_val), "Associated UserExam should NOT be destroyed."
    assert ExamQuestion.exists?(exam_question_id_val), "Associated ExamQuestion should NOT be destroyed."
    assert Answer.exists?(answer_id_val), "Associated Answer should NOT be destroyed."
  end
end

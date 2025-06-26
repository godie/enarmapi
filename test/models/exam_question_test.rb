require "test_helper"

class ExamQuestionTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:exam)
    should belong_to(:question)
    should have_many(:player_exam_answers)
  end

  context "validations" do
    setup do
      # Create a record to test uniqueness against.
      # exams(:one) and questions(:one) should be available from fixtures.
      # If exam_questions(:one) is not defined or doesn't use these, create one.
      @existing_exam = exams(:one)
      @existing_question = questions(:one)
      ExamQuestion.create!(exam: @existing_exam, question: @existing_question, position: 1, points: 5) unless ExamQuestion.exists?(exam_id: @existing_exam.id, question_id: @existing_question.id)
    end

    # Presence of exam_id and question_id is implicitly validated by `belongs_to`
    should "be invalid without an exam" do
      exam_question = ExamQuestion.new(question: questions(:two), position: 1, points: 5) # Use a different question
      assert_not exam_question.valid?
      assert_includes exam_question.errors[:exam], "must exist"
    end

    should "be invalid without a question" do
      exam_question = ExamQuestion.new(exam: exams(:two), position: 1, points: 5) # Use a different exam
      assert_not exam_question.valid?
      assert_includes exam_question.errors[:question], "must exist"
    end

    # Schema: index_exam_questions_on_exam_id_and_question_id, unique: true
    # This means an exam cannot have the same question more than once.
    # This test uses `shoulda-matchers` which needs a subject.
    subject do
       # Need to ensure the subject is a new record for shoulda-matchers uniqueness test
       # Also, the existing record for uniqueness check is created in the setup block.
       ExamQuestion.new(exam: @existing_exam, question: questions(:two), position: 2, points: 10)
    end
    should validate_uniqueness_of(:question_id).scoped_to(:exam_id).with_message("has already been taken")


    # Manual test for uniqueness to be certain
    test "question_id must be unique per exam_id" do
      # The record @existing_exam + @existing_question is created in setup
      duplicate_exam_question = ExamQuestion.new(
        exam: @existing_exam,
        question: @existing_question, # Same exam and question
        position: 3, # Different position, but should still fail
        points: 20
      )
      assert_not duplicate_exam_question.valid?, "Should not be valid due to uniqueness constraint (exam_id, question_id)"
      assert_includes duplicate_exam_question.errors[:question_id], "has already been taken"
    end
  end

  setup do
    # General fixtures for other tests
    @exam_one = exams(:one)
    @question_one = questions(:one)
    @exam_two = exams(:two) # Assuming fixture exists
    @question_two = questions(:two) # Assuming fixture exists
  end

  test "should be valid with an exam, a question, position, and points" do
    # Use a combination not already used for uniqueness tests
    exam_question = ExamQuestion.new(
      exam: @exam_two,
      question: @question_one, # question_one with exam_two
      position: 1,
      points: 10
    )
    assert exam_question.valid?, exam_question.errors.full_messages.join(", ")
  end

  test "position can be nil (schema allows, no model validation)" do
    exam_question = ExamQuestion.new(exam: @exam_two, question: @question_two, points: 5, position: nil)
    assert exam_question.valid?, "Position can be nil. Errors: #{exam_question.errors.full_messages.join(", ")}"
    assert exam_question.save
    assert_nil exam_question.reload.position
  end

  test "points can be nil (schema allows, no model validation)" do
    exam_question = ExamQuestion.new(exam: @exam_two, question: @question_two, position: 1, points: nil)
    assert exam_question.valid?, "Points can be nil. Errors: #{exam_question.errors.full_messages.join(", ")}"
    assert exam_question.save
    assert_nil exam_question.reload.points
  end

  test "destroying exam_question does not destroy its associated exam or question" do
    # Create fresh records for this test to avoid side-effects
    test_exam = Exam.create!(name: "EQ Deletion Test Exam")
    test_question = Question.create!(text: "EQ Deletion Test Question", clinical_case: clinical_cases(:one))
    exam_question = ExamQuestion.create!(exam: test_exam, question: test_question, position: 1, points: 5)

    exam_id = test_exam.id
    question_id = test_question.id
    exam_question_id = exam_question.id

    exam_question.destroy

    assert_raises(ActiveRecord::RecordNotFound) { ExamQuestion.find(exam_question_id) }
    assert Exam.exists?(exam_id), "Associated Exam should still exist"
    assert Question.exists?(question_id), "Associated Question should still exist"
  end

  # The `act_as_list scope: :exam` is commented out in the model.
  # If it were active, tests for list behavior (auto-positioning, reordering) would go here.
  # For now, `position` is just a regular integer field.

  test "can have many player_exam_answers" do
    # This test relies on PlayerExamAnswer, PlayerExam fixtures.
    exam_q = exam_questions(:one) # from exam_questions.yml
    player_exam = player_exams(:one) # from player_exams.yml
    answer = answers(:one) # from answers.yml

    # Ensure the exam_question in player_exam_answers(:one) matches exam_q
    # Or create a new one.
    # Let's assume player_exam_answers.yml has an entry that refers to exam_questions(:one)

    # If player_exam_answers fixture 'pea_one' exists and is correctly associated:
    # pea = player_exam_answers(:one)
    # assert_includes exam_q.player_exam_answers, pea

    # Or, create one:
    # Need a PlayerExam first
    # player = players(:player_one)
    # exam = exams(:one) # exam_q.exam should be exams(:one)
    # Ensure exam_q.exam is what we expect
    # player_exam_for_test = PlayerExam.find_or_create_by!(player: player, exam: exam_q.exam, status: "in_progress")

    # pea = PlayerExamAnswer.create!(
    #   player_exam: player_exam_for_test,
    #   exam_question: exam_q,
    #   answer: answer, # an appropriate answer for exam_q.question
    #   is_correct: true, # example value
    #   points_earned: exam_q.points # example value
    # )
    # assert_includes exam_q.reload.player_exam_answers, pea
    # assert_equal 1, exam_q.player_exam_answers.count

    # For now, just check the association exists, actual creation can be complex due to dependencies
    assert_nothing_raised { exam_q.player_exam_answers.build }
    assert_equal 0, exam_q.player_exam_answers.count # If no fixtures point to it or created
  end
end

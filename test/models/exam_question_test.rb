require "test_helper"

class ExamQuestionTest < ActiveSupport::TestCase
  # Associations
  test "should belong to exam" do
    eq = ExamQuestion.new
    assert_respond_to eq, :exam
    assert_respond_to eq, :exam_id
  end

  test "should belong to question" do
    eq = ExamQuestion.new
    assert_respond_to eq, :question
    assert_respond_to eq, :question_id
  end

  test "should have many player_exam_answers" do
    eq = ExamQuestion.new
    assert_respond_to eq, :player_exam_answers
    # Dependent destroy for player_exam_answers is not specified in model,
    # so not tested here unless it becomes a requirement.
  end

  # Validations
  setup do
    # For uniqueness validation and general tests
    @exam_one = exams(:one)
    @question_one = questions(:one)
    @question_two = questions(:two) # Another question for the same exam

    # Create an existing ExamQuestion for uniqueness testing
    # This one uses @exam_one and @question_one
    ExamQuestion.find_or_create_by!(exam: @exam_one, question: @question_one) do |eq_setup|
      eq_setup.position = 1
      eq_setup.points = 10
    end
  end

  test "should be invalid without an exam" do
    exam_question = ExamQuestion.new(question: @question_one, position: 1, points: 5)
    assert_not exam_question.valid?, "ExamQuestion should be invalid without an exam"
    assert_includes exam_question.errors[:exam], "must exist"
  end

  test "should be invalid without a question" do
    exam_question = ExamQuestion.new(exam: @exam_one, position: 1, points: 5)
    assert_not exam_question.valid?, "ExamQuestion should be invalid without a question"
    assert_includes exam_question.errors[:question], "must exist"
  end

  test "question_id must be unique scoped to exam_id" do
    # An ExamQuestion with @exam_one and @question_one already exists from setup.
    duplicate_exam_question = ExamQuestion.new(
      exam: @exam_one,       # Same exam
      question: @question_one, # Same question
      position: 2,           # Different position, but should still fail on (exam, question) uniqueness
      points: 20
    )
    assert_not duplicate_exam_question.valid?, "Should not be valid due to (exam_id, question_id) uniqueness constraint"
    # Default message for uniqueness is "has already been taken".
    # It applies to the attribute being validated for uniqueness within the scope.
    assert_includes duplicate_exam_question.errors[:question_id], "has already been taken"
  end

  # General attributes and validity
  test "should be valid with an exam, a question, position, and points" do
    # Use a combination not used in setup for uniqueness to ensure this one is valid on its own.
    # @exam_one and @question_two combination.
    exam_question = ExamQuestion.new(
      exam: @exam_one,
      question: @question_two, # Different question for the same exam
      position: 1,
      points: 10
    )
    assert exam_question.valid?, exam_question.errors.full_messages.join(", ")
  end

  test "position attribute can be nil (if schema allows and no model validation)" do
    # Schema: t.integer "position" (nullable)
    exam_question = ExamQuestion.new(exam: @exam_one, question: @question_two, points: 5, position: nil)
    assert exam_question.valid?, "Position being nil should be valid. Errors: #{exam_question.errors.full_messages.join(", ")}"
    assert exam_question.save
    assert_nil exam_question.reload.position
  end

  test "points attribute can be nil (if schema allows and no model validation)" do
    # Schema: t.integer "points" (nullable)
    exam_question = ExamQuestion.new(exam: @exam_one, question: @question_two, position: 1, points: nil)
    assert exam_question.valid?, "Points being nil should be valid. Errors: #{exam_question.errors.full_messages.join(", ")}"
    assert exam_question.save
    assert_nil exam_question.reload.points
  end

  test "destroying an ExamQuestion does not destroy its associated Exam or Question" do
    # Create fresh, un-fixture records for this specific test to avoid side effects.
    test_exam = Exam.create!(name: "EQ Deletion Test - Exam")
    # Ensure clinical_case exists for the question
    cc = clinical_cases(:one) ? clinical_cases(:one) : ClinicalCase.create!(name: "Temp CC", category: categories(:one), description:"d")
    test_question = Question.create!(text: "EQ Deletion Test - Question", clinical_case: cc)

    exam_question_to_delete = ExamQuestion.create!(exam: test_exam, question: test_question, position: 1, points: 5)

    exam_id_before_delete = test_exam.id
    question_id_before_delete = test_question.id
    exam_question_id_to_delete = exam_question_to_delete.id

    exam_question_to_delete.destroy

    assert_raises(ActiveRecord::RecordNotFound) { ExamQuestion.find(exam_question_id_to_delete) }
    assert Exam.exists?(exam_id_before_delete), "Associated Exam should still exist after ExamQuestion deletion."
    assert Question.exists?(question_id_before_delete), "Associated Question should still exist after ExamQuestion deletion."
  end

  # The `act_as_list scope: :exam` is commented out in the model.
  # If it were active, tests for list behavior (auto-positioning, reordering on destroy/move) would go here.
  # Since `position` is just a regular integer field currently, no specific list tests are needed beyond basic assignment.

  test "can have associated player_exam_answers" do
    # This test is primarily for the association's existence.
    # More detailed interaction tests would involve PlayerExamAnswer creation.
    exam_q_from_fixture = exam_questions(:eq_exam1_q1) # from exam_questions.yml

    assert_nothing_raised { exam_q_from_fixture.player_exam_answers.build } # Check if `build` works

    # If fixtures for PlayerExamAnswer exist and are linked to exam_questions(:eq_exam1_q1),
    # then `exam_q_from_fixture.player_exam_answers.count` would be > 0.
    # Example: player_exam_answers(:pea_for_eq1_q1) if defined.
    # For now, just ensuring the association method itself doesn't error.
    # A more robust test would be:
    # player_exam = player_exams(:one) # Assuming this PE is for the same exam as eq_exam1_q1
    # answer = answers(:one) # Assuming this answer is for eq_exam1_q1.question
    # pea = PlayerExamAnswer.create!(player_exam: player_exam, exam_question: exam_q_from_fixture, answer: answer)
    # assert_includes exam_q_from_fixture.reload.player_exam_answers, pea
    # pea.destroy # Clean up

    # Current simple check:
    assert_equal 0, exam_q_from_fixture.player_exam_answers.count, "Expected 0 player_exam_answers if none are fixture-linked or created."
    # This might be brittle if fixtures *do* link some. A specific setup for this test might be better.
  end
end

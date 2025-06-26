require "test_helper"

class ExamTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:exam_questions).dependent(:destroy).order(:position)
    should have_many(:questions).through(:exam_questions)
    should have_many(:player_exams).dependent(:destroy)
    should accept_nested_attributes_for(:exam_questions).allow_destroy(true)
  end

  context "validations" do
    should validate_presence_of(:name)
    # The model has `description` commented out for presence validation.
    # If it were active: should validate_presence_of(:description)
  end

  setup do
    # Using fixtures for general setup
    @exam_one = exams(:one)
    @question1 = questions(:one)
    @question2 = questions(:two)
    @player_one = players(:player_one)
  end

  test "should be valid with a name" do
    exam = Exam.new(name: "Valid Exam Name")
    assert exam.valid?, exam.errors.full_messages.join(", ")
    exam.description = "Optional description for this valid exam."
    assert exam.valid?
  end

  test "attributes should allow nil for non-validated fields like description, time_limit, passing_score" do
    exam = Exam.new(name: "Exam With Nil Optional Fields")
    exam.description = nil
    exam.time_limit = nil
    exam.passing_score = nil
    # 'active' defaults to true in schema.
    assert exam.valid?, "Exam should be valid with nil optional fields. Errors: #{exam.errors.full_messages.join(", ")}"
    assert exam.save
    exam.reload
    assert_nil exam.description
    assert_nil exam.time_limit
    assert_nil exam.passing_score
  end

  test "active attribute should default to true on new record" do
    exam = Exam.new(name: "Newly Created Active Exam")
    # Default value is applied by the database, so it might not be visible until save.
    # However, Rails can also infer defaults from schema.
    # Let's save to be sure.
    assert exam.save
    assert_equal true, exam.reload.active, "Active should default to true"
  end

   test "can explicitly set active to false" do
    exam = Exam.create!(name: "Inactive Exam", active: false)
    assert_equal false, exam.reload.active
  end

  test "can accept nested attributes for creating exam_questions" do
    attributes = {
      name: "Exam with New Nested ExamQuestions",
      exam_questions_attributes: [
        { question_id: @question1.id, position: 1, points: 10 },
        { question_id: @question2.id, position: 2, points: 5 }
      ]
    }
    exam = Exam.new(attributes)
    assert exam.valid?, "Exam should be valid. Errors: #{exam.errors.full_messages.join(", ")}"
    assert exam.save, "Failed to save exam. Errors: #{exam.errors.full_messages.join(", ")}"
    exam.reload # Reload to ensure exam_questions are loaded from DB
    assert_equal 2, exam.exam_questions.count
    assert_equal @question1, exam.exam_questions.find_by(position: 1)&.question
    assert_equal 10, exam.exam_questions.find_by(position: 1)&.points
  end

  test "destroying exam destroys associated exam_questions" do
    # Use a fresh exam to avoid fixture side effects if any
    exam_to_destroy = Exam.create!(name: "Exam for Destruction Test EQ")
    ExamQuestion.create!(exam: exam_to_destroy, question: @question1, position: 1, points: 5)
    ExamQuestion.create!(exam: exam_to_destroy, question: @question2, position: 2, points: 5)

    exam_question_ids = exam_to_destroy.exam_questions.pluck(:id)
    assert_equal 2, exam_question_ids.count, "Should have 2 exam questions before destroy"

    exam_to_destroy.destroy

    assert_raises(ActiveRecord::RecordNotFound) { Exam.find(exam_to_destroy.id) }
    exam_question_ids.each do |id|
      assert_raises(ActiveRecord::RecordNotFound) { ExamQuestion.find(id) }
    end
  end

  test "destroying exam destroys associated player_exams" do
    exam_to_destroy = Exam.create!(name: "Exam with PlayerExams for Destruction Test PE")
    PlayerExam.create!(exam: exam_to_destroy, player: @player_one, status: "started")

    player_exam_ids = exam_to_destroy.player_exams.pluck(:id)
    assert_equal 1, player_exam_ids.count, "Should have 1 player exam before destroy"

    exam_to_destroy.destroy

    assert_raises(ActiveRecord::RecordNotFound) { Exam.find(exam_to_destroy.id) }
    player_exam_ids.each do |id|
      assert_raises(ActiveRecord::RecordNotFound) { PlayerExam.find(id) }
    end
  end

  test "exam_questions association is ordered by position" do
    exam_with_ordered_eqs = Exam.create!(name: "Ordered EQs Association Exam")
    eq_pos2 = ExamQuestion.create!(exam: exam_with_ordered_eqs, question: @question2, position: 2, points: 5)
    eq_pos1 = ExamQuestion.create!(exam: exam_with_ordered_eqs, question: @question1, position: 1, points: 10)

    # Fetch them through the association, which should apply the order
    fetched_eqs = exam_with_ordered_eqs.exam_questions.reload
    assert_equal [eq_pos1.id, eq_pos2.id], fetched_eqs.map(&:id), "ExamQuestions should be ordered by position"
  end

  context "#total_points" do
    should "calculate the sum of points from its exam_questions" do
      exam = Exam.create!(name: "Points Sum Test Exam")
      ExamQuestion.create!(exam: exam, question: @question1, position: 1, points: 10)
      ExamQuestion.create!(exam: exam, question: @question2, position: 2, points: 7)
      assert_equal 17, exam.total_points
    end

    should "return 0 if there are no exam_questions" do
      exam = Exam.create!(name: "No EQs Exam For Points")
      assert_equal 0, exam.total_points
    end

    should "return 0 if exam_questions have nil points" do
      exam = Exam.create!(name: "Nil Points Sum Exam")
      ExamQuestion.create!(exam: exam, question: @question1, position: 1, points: nil)
      ExamQuestion.create!(exam: exam, question: @question2, position: 2, points: nil)
      # `sum(:points)` in SQL typically treats NULLs as 0 in the sum, or ignores them.
      # If all are NULL, sum is often 0.
      assert_equal 0, exam.total_points
    end

    should "correctly sum points when some are nil and some are not" do
      exam = Exam.create!(name: "Mixed Points Exam")
      ExamQuestion.create!(exam: exam, question: @question1, position: 1, points: 10)
      ExamQuestion.create!(exam: exam, question: @question2, position: 2, points: nil)
      assert_equal 10, exam.total_points
    end
  end

  test "can update nested exam_questions attributes" do
    exam_for_update = Exam.create!(name: "Exam for updating EQs Test")
    eq = ExamQuestion.create!(exam: exam_for_update, question: @question1, position: 1, points: 5)

    exam_for_update.update!(exam_questions_attributes: [
      { id: eq.id, points: 15 } # Update points
    ])
    assert_equal 15, eq.reload.points
  end

  test "can destroy nested exam_questions using _destroy attribute" do
    exam_for_destroy_nested = Exam.create!(name: "Exam for destroying nested EQs Test")
    eq_to_keep = ExamQuestion.create!(exam: exam_for_destroy_nested, question: @question1, position: 1, points: 5)
    eq_to_destroy = ExamQuestion.create!(exam: exam_for_destroy_nested, question: @question2, position: 2, points: 10)

    assert_equal 2, exam_for_destroy_nested.exam_questions.count

    exam_for_destroy_nested.update!(exam_questions_attributes: [
      { id: eq_to_destroy.id, _destroy: "1" } # Mark for destruction
    ])
    exam_for_destroy_nested.reload # Reload to see changes from DB

    assert_equal 1, exam_for_destroy_nested.exam_questions.count, "Should have one exam_question left"
    assert_equal eq_to_keep, exam_for_destroy_nested.exam_questions.first
    assert_raises(ActiveRecord::RecordNotFound) { ExamQuestion.find(eq_to_destroy.id) }
  end
end

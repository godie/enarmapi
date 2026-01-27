require "test_helper"

class ExamTest < ActiveSupport::TestCase
  fixtures :exams, :categories, :questions, :users
  # Associations
  test "should have many exam_questions, ordered by position, and dependent destroy" do
    exam = Exam.new
    assert_respond_to exam, :exam_questions

    # Test dependent destroy and order
    exam_with_eqs = Exam.create!(name: "Exam for EQ Order/Destroy Test", category: categories(:one))
    q1 = questions(:one)
    q2 = questions(:two)

    # Create out of order to test ordering
    eq_pos2 = ExamQuestion.create!(exam: exam_with_eqs, question: q2, position: 2, points: 5)
    eq_pos1 = ExamQuestion.create!(exam: exam_with_eqs, question: q1, position: 1, points: 10)

    exam_with_eqs.reload # Reload to get ordered exam_questions
    assert_equal [ eq_pos1.id, eq_pos2.id ], exam_with_eqs.exam_questions.map(&:id), "ExamQuestions not ordered by position"

    eq_ids = exam_with_eqs.exam_questions.pluck(:id)
    assert_difference "ExamQuestion.count", -eq_ids.size do
      exam_with_eqs.destroy
    end
    eq_ids.each { |id| assert_not ExamQuestion.exists?(id) }
  end

  test "should have many questions through exam_questions" do
    exam = Exam.new
    assert_respond_to exam, :questions
  end

  test "should have many user_exams and dependent destroy" do
    exam = Exam.new
    assert_respond_to exam, :user_exams

    # Test dependent destroy
    exam_with_ues = Exam.create!(name: "Exam for UE Destroy Test", category: categories(:one))
    user = users(:player_one)
    ue = UserExam.create!(exam: exam_with_ues, user: user, status: "started")
    ue_id = ue.id

    assert_difference "UserExam.count", -1 do
      exam_with_ues.destroy
    end
    assert_not UserExam.exists?(ue_id)
  end

  test "should accept nested attributes for exam_questions and allow destroy" do
    exam = Exam.new
    assert_respond_to exam, :exam_questions_attributes=
    # Further tests for functionality are below
  end

  # Validations
  test "should validate presence of name" do
    exam = Exam.new(description: "An exam without a name.")
    assert_not exam.valid?, "Exam should be invalid without a name"
    assert_includes exam.errors[:name], "can't be blank"
  end

  test "should validate presence of category" do
    exam = Exam.new(name: "exam name", description: "An exam without a name.")
    assert_not exam.valid?, "Exam should be invalid without a category"
    assert_includes exam.errors[:category], "must exist"
  end
  # Description presence is not validated in the model.

  # Setup for general tests
  setup do
    @exam_one_fixture = exams(:exam_one_urgencias) # Fixture: "Cardiology Basics"
    @question1_fixture = questions(:one)
    @question2_fixture = questions(:two)
    @player_one_fixture = users(:player_one)
  end

  test "should be valid with just a name" do
    exam = Exam.new(name: "A Perfectly Valid Exam Name", category: categories(:one))
    assert exam.valid?, exam.errors.full_messages.join(", ")
    exam.description = "This is an optional description."
    assert exam.valid? # Still valid with description
  end

  test "optional attributes (description, time_limit, passing_score) can be nil" do
    exam = Exam.new(name: "Exam With Nil Optionals", category: categories(:one))
    exam.description = nil
    exam.time_limit = nil
    exam.passing_score = nil
    assert exam.valid?, "Exam should be valid with nil optional fields. Errors: #{exam.errors.full_messages.join(", ")}"
    assert exam.save
    exam.reload
    assert_nil exam.description
    assert_nil exam.time_limit
    assert_nil exam.passing_score
  end

  test "active attribute should default to true on new record creation" do
    exam = Exam.new(name: "Newly Created Exam For Active Test", category: categories(:one))
    # Default value is from DB schema `default: true`
    assert exam.save
    assert_equal true, exam.reload.active, "'active' attribute should default to true"
  end

  test "active attribute can be explicitly set to false" do
    exam = Exam.create!(name: "An Inactive Exam", active: false, category: categories(:one))
    assert_equal false, exam.reload.active
  end

  test "can accept nested attributes for creating exam_questions" do
    attributes = {
      category_id: categories(:one).id,
      name: "Exam Created with Nested EQs",
      exam_questions_attributes: [
        { question_id: @question1_fixture.id, position: 1, points: 10 },
        { question_id: @question2_fixture.id, position: 2, points: 5 }
      ]
    }
    exam = Exam.new(attributes)
    assert exam.valid?, "Exam with nested EQs should be valid. Errors: #{exam.errors.full_messages.join(", ")}"
    assert exam.save, "Failed to save exam with nested EQs. Errors: #{exam.errors.full_messages.join(", ")}"
    exam.reload # Reload to get EQs from DB
    assert_equal 2, exam.exam_questions.count, "Should have created 2 exam_questions"
    assert_equal @question1_fixture, exam.exam_questions.find_by(position: 1)&.question
    assert_equal 10, exam.exam_questions.find_by(position: 1)&.points
  end

  test "can update nested exam_questions attributes" do
    exam_for_update = Exam.create!(name: "Exam for Updating Nested EQs", category: categories(:one))
    eq_to_update = ExamQuestion.create!(exam: exam_for_update, question: @question1_fixture, position: 1, points: 5)

    exam_for_update.update!(exam_questions_attributes: [
      { id: eq_to_update.id, points: 15, position: 2 } # Update points and position
    ])
    eq_to_update.reload
    assert_equal 15, eq_to_update.points
    assert_equal 2, eq_to_update.position
  end

  test "can destroy nested exam_questions using _destroy attribute flag" do
    exam_for_destroy_nested = Exam.create!(name: "Exam for Destroying Nested EQs", category: categories(:one))
    eq_kept = ExamQuestion.create!(exam: exam_for_destroy_nested, question: @question1_fixture, position: 1, points: 5)
    eq_destroyed = ExamQuestion.create!(exam: exam_for_destroy_nested, question: @question2_fixture, position: 2, points: 10)

    assert_equal 2, exam_for_destroy_nested.exam_questions.count

    exam_for_destroy_nested.update!(exam_questions_attributes: [
      { id: eq_destroyed.id, _destroy: "1" } # Mark for destruction
    ])
    exam_for_destroy_nested.reload

    assert_equal 1, exam_for_destroy_nested.exam_questions.count, "Should have one exam_question remaining"
    assert_equal eq_kept, exam_for_destroy_nested.exam_questions.first
    assert_raises(ActiveRecord::RecordNotFound) { ExamQuestion.find(eq_destroyed.id) }
  end

  # Instance Method: total_points
  test "total_points should calculate the sum of points from its exam_questions" do
    exam = Exam.create!(name: "Points Summation Test Exam", category: categories(:one))
    ExamQuestion.create!(exam: exam, question: @question1_fixture, position: 1, points: 10)
    ExamQuestion.create!(exam: exam, question: @question2_fixture, position: 2, points: 7)
    assert_equal 17, exam.total_points
  end

  test "total_points should return 0 if there are no exam_questions" do
    exam = Exam.create!(name: "No EQs Exam - Points Test", category: categories(:one))
    assert_equal 0, exam.total_points
  end

  test "total_points should return 0 if exam_questions have nil points" do
    exam = Exam.create!(name: "Nil Points Exam - Points Test", category: categories(:one))
    ExamQuestion.create!(exam: exam, question: @question1_fixture, position: 1, points: nil)
    ExamQuestion.create!(exam: exam, question: @question2_fixture, position: 2, points: nil)
    # SQL SUM of NULLs is typically 0 (or NULL, but Rails sum treats nil as 0).
    assert_equal 0, exam.total_points
  end

  test "total_points should correctly sum points when some are nil and others are not" do
    exam = Exam.create!(name: "Mixed Nil/Value Points Exam", category: categories(:one))
    ExamQuestion.create!(exam: exam, question: @question1_fixture, position: 1, points: 10)
    ExamQuestion.create!(exam: exam, question: @question2_fixture, position: 2, points: nil) # This one has nil points
    assert_equal 10, exam.total_points
  end
end

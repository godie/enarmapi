require "test_helper"

class ClinicalCaseTest < ActiveSupport::TestCase
  # Associations
  test "should belong to category" do
    clinical_case = ClinicalCase.new
    assert_respond_to clinical_case, :category
    assert_respond_to clinical_case, :category_id
  end

  test "should have many questions and they should be dependent destroy" do
    clinical_case = ClinicalCase.new
    assert_respond_to clinical_case, :questions

    # Test dependent destroy
    cc_with_questions = ClinicalCase.create!(name: "CC for Q Destroy Test", category: categories(:one), description: "Test")
    question = Question.create!(text: "Q in CC for Destroy", clinical_case: cc_with_questions)
    question_id = question.id

    assert_difference "Question.count", -1 do
      cc_with_questions.destroy
    end
    assert_not Question.exists?(question_id)
  end

  test "should accept nested attributes for questions and allow destroy" do
    # Test accepts_nested_attributes_for by creating/updating with nested params
    # Test allow_destroy by using _destroy flag
    clinical_case = ClinicalCase.new
    assert_respond_to clinical_case, :questions_attributes=

    # Further tests for nested attributes functionality are below (e.g., test "can accept nested attributes for creating questions")
  end

  # Validations
  test "should validate presence of name" do
    clinical_case = ClinicalCase.new(category: categories(:one), description: "A case without a name")
    assert_not clinical_case.valid?, "Clinical case should be invalid without a name"
    assert_includes clinical_case.errors[:name], "can't be blank"
  end

  test "should be invalid without a category" do
    clinical_case = ClinicalCase.new(name: "Case without category association")
    assert_not clinical_case.valid?, "Clinical case should be invalid without a category"
    assert_includes clinical_case.errors[:category], "must exist" # `belongs_to` adds this
  end

  # Setup for general tests
  setup do
    @category = categories(:one) # From fixtures
  end

  test "should be valid with a name and category" do
    clinical_case = ClinicalCase.new(
      name: "Valid Clinical Case Name",
      description: "This is an optional description.",
      category: @category
    )
    assert clinical_case.valid?, clinical_case.errors.full_messages.join(", ")
  end

  test "description attribute can be nil" do
    clinical_case = ClinicalCase.new(name: "Case With No Description", category: @category)
    assert clinical_case.valid?
    assert clinical_case.save
    assert_nil clinical_case.reload.description
  end

  test "can accept nested attributes for creating questions" do
    attributes = {
      name: "Case Created with Nested Questions",
      category_id: @category.id,
      description: "Test case description",
      questions_attributes: [
        { text: "First nested question text" },
        { text: "Second nested question text" }
      ]
    }
    assert Category.find_by(id: @category.id), "Prerequisite: Category with ID #{@category.id} must exist"

    clinical_case = ClinicalCase.new(attributes)

    assert clinical_case.valid?, "ClinicalCase with nested Qs should be valid. Errors: #{clinical_case.errors.full_messages.join(", ")}"
    assert clinical_case.save, "Failed to save ClinicalCase with nested Qs. Errors: #{clinical_case.errors.full_messages.join(", ")}"
    clinical_case.reload # Reload to get questions from DB
    assert_equal 2, clinical_case.questions.count, "Should have created 2 questions via nesting"
    assert_equal "First nested question text", clinical_case.questions.first.text
  end

  test "can update nested questions' attributes" do
    clinical_case_to_update = ClinicalCase.create!(name: "Case for Updating Nested Qs", category: @category, description: "Test")
    question = Question.create!(text: "Initial Q text", clinical_case: clinical_case_to_update)

    clinical_case_to_update.update!(questions_attributes: [
      { id: question.id, text: "Updated Q text" }
    ])
    assert_equal "Updated Q text", question.reload.text
  end

  test "can destroy nested questions using _destroy attribute flag" do
    cc_for_destroy_nested_q = ClinicalCase.create!(name: "Case for Destroying Nested Q", category: @category, description: "Test")
    q_to_keep = Question.create!(text: "Question to be kept", clinical_case: cc_for_destroy_nested_q)
    q_to_destroy = Question.create!(text: "Question to be destroyed", clinical_case: cc_for_destroy_nested_q)

    assert_equal 2, cc_for_destroy_nested_q.questions.count

    cc_for_destroy_nested_q.update!(questions_attributes: [
      { id: q_to_destroy.id, _destroy: "1" } # Mark for destruction
    ])
    cc_for_destroy_nested_q.reload # Reload from DB

    assert_equal 1, cc_for_destroy_nested_q.questions.count, "Should have one question remaining"
    assert_equal q_to_keep, cc_for_destroy_nested_q.questions.first
    assert_raises(ActiveRecord::RecordNotFound) { Question.find(q_to_destroy.id) }
  end

  test "per_page class attribute should be 10 (will_paginate convention)" do
    # This tests the class attribute `self.per_page` often used by will_paginate.
    # If Kaminari is used (`paginates_per`), this test would need adjustment.
    assert_equal 10, ClinicalCase.per_page
  end
end

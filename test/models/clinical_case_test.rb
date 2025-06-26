require "test_helper"

class ClinicalCaseTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:category)
    should have_many(:questions).dependent(:destroy)
    should accept_nested_attributes_for(:questions).allow_destroy(true)
  end

  context "validations" do
    should validate_presence_of(:name)
    # Note: presence of category_id is implicitly validated by `belongs_to :category`
    # Explicit test for category presence:
    should "be invalid without a category" do
      clinical_case = ClinicalCase.new(name: "Case without category")
      assert_not clinical_case.valid?
      assert_includes clinical_case.errors[:category], "must exist"
    end
  end

  setup do
    @category = categories(:one) # From fixtures
  end

  test "should be valid with a name and category" do
    clinical_case = ClinicalCase.new(
      name: "Valid Clinical Case",
      description: "This is a description.",
      category: @category
    )
    assert clinical_case.valid?, clinical_case.errors.full_messages.join(", ")
  end

  test "description can be nil" do
    clinical_case = ClinicalCase.new(name: "Case with no description", category: @category)
    assert clinical_case.valid?
    assert clinical_case.save
    assert_nil clinical_case.reload.description
  end

  test "can accept nested attributes for creating questions" do
    attributes = {
      name: "Case with Nested Questions",
      category_id: @category.id,
      description: "Test case",
      questions_attributes: [
        { text: "First nested question" },
        { text: "Second nested question" }
      ]
    }
    # Ensure the category exists if using category_id directly without the object
    assert Category.find_by(id: @category.id), "Category with ID #{@category.id} must exist"

    clinical_case = ClinicalCase.new(attributes)

    assert clinical_case.valid?, "ClinicalCase should be valid with nested questions. Errors: #{clinical_case.errors.full_messages.join(", ")}"
    assert clinical_case.save, "Failed to save ClinicalCase with nested questions. Errors: #{clinical_case.errors.full_messages.join(", ")}"
    assert_equal 2, clinical_case.questions.count, "Should have created 2 questions"
    assert_equal "First nested question", clinical_case.questions.first.text
  end

  test "can destroy associated questions when clinical case is destroyed" do
    clinical_case = ClinicalCase.create!(name: "Case to be destroyed", category: @category, description: "Test")
    # Use create! for questions to ensure they are persisted
    Question.create!(text: "Q1 for deletion test", clinical_case: clinical_case)
    Question.create!(text: "Q2 for deletion test", clinical_case: clinical_case)

    assert_equal 2, clinical_case.questions.count
    question_ids = clinical_case.questions.pluck(:id)

    clinical_case.destroy
    assert_raises(ActiveRecord::RecordNotFound) { ClinicalCase.find(clinical_case.id) }
    question_ids.each do |id|
      assert_raises(ActiveRecord::RecordNotFound) { Question.find(id) }
    end
    assert_equal 0, Question.where(id: question_ids).count
  end

  test "can update nested questions attributes" do
    clinical_case = ClinicalCase.create!(name: "Case for updating questions", category: @category, description: "Test")
    question = Question.create!(text: "Initial question text", clinical_case: clinical_case)

    clinical_case.update!(questions_attributes: [
      { id: question.id, text: "Updated question text" }
    ])
    assert_equal "Updated question text", question.reload.text
  end

  test "can destroy nested questions using _destroy attribute" do
    clinical_case = ClinicalCase.create!(name: "Case for destroying nested Q", category: @category, description: "Test")
    question_to_keep = Question.create!(text: "Question to keep", clinical_case: clinical_case)
    question_to_destroy = Question.create!(text: "Question to destroy", clinical_case: clinical_case)

    assert_equal 2, clinical_case.questions.count

    clinical_case.update!(questions_attributes: [
      { id: question_to_destroy.id, _destroy: "1" } # "1", true, or "true" should work
    ])

    assert_equal 1, clinical_case.questions.count, "Should have one question left"
    assert_equal question_to_keep, clinical_case.questions.first
    assert_raises(ActiveRecord::RecordNotFound) { Question.find(question_to_destroy.id) }
  end

  test "per_page should be 10 (will_paginate convention)" do
    # This tests the class attribute `self.per_page` often used by will_paginate.
    # If another pagination gem is used (e.g., Kaminari's `paginates_per`), this test would need adjustment.
    assert_equal 10, ClinicalCase.per_page
  end

  test "name validation failure" do
    clinical_case = ClinicalCase.new(category: @category, description: "Test")
    assert_not clinical_case.valid?
    assert_includes clinical_case.errors[:name], "can't be blank"
  end
end

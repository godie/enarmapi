require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  fixtures :categories, :clinical_cases, :players

  setup do
    @category_one = categories(:one)
    @category_two = categories(:two)
    @clinical_case_one = clinical_cases(:one) # Belongs to category_one
    @clinical_case_two = clinical_cases(:two) # Belongs to category_two
    @player_one = players(:player_one)
  end

  # Associations
  test "should belong to clinical_case (optional)" do
    q = Question.new
    assert_respond_to q, :clinical_case
    assert_respond_to q, :clinical_case_id
  end

  test "should belong to category (optional)" do
    q = Question.new
    assert_respond_to q, :category
    assert_respond_to q, :category_id
  end

  test "should have many answers and they should be dependent destroy" do
    q = Question.new
    assert_respond_to q, :answers

    question_with_answers = Question.create!(text: "Q for Answer Destroy Test", clinical_case: @clinical_case_one)
    ans = Answer.create!(question: question_with_answers, text: "Ans for Q Destroy Test", is_correct: true)

    assert_difference "Answer.count", -1 do
      question_with_answers.destroy
    end
    assert_not Answer.exists?(ans.id)
  end

  test "should accept nested attributes for answers and allow destroy" do
    q = Question.new
    assert_respond_to q, :answers_attributes=
  end

  # Validations
  test "should validate presence of text" do
    question = Question.new(category: @category_one) # No text
    assert_not question.valid?, "Question should be invalid without text"
    assert_includes question.errors[:text], "can't be blank"
  end

  test "should be invalid without either a clinical_case or a category" do
    question = Question.new(text: "A question text without any association.")
    assert_not question.valid?, "Question should be invalid without clinical_case or category"
    assert_includes question.errors[:base], "Question must be associated with a clinical case or a category"
  end

  test "should be invalid if associated with both a clinical_case and a category directly" do
    question = Question.new(text: "A question text with both associations.", clinical_case: @clinical_case_one, category: @category_one)
    assert_not question.valid?, "Question should be invalid if associated with both clinical_case and category"
    assert_includes question.errors[:base], "Question cannot be associated with both a clinical case and a category directly"
  end

  test "should be valid with text and an associated clinical_case" do
    question = Question.new(text: "Valid question with clinical case", clinical_case: @clinical_case_one)
    assert question.valid?, question.errors.full_messages.join(", ")
  end

  test "should be valid with text and an associated category (standalone)" do
    question = Question.new(text: "Valid standalone question with category", category: @category_one)
    assert question.valid?, question.errors.full_messages.join(", ")
  end

  # Nested Attributes for Answers
  test "can accept and create nested answers for question with clinical_case" do
    attributes = {
      text: "Question with CC and nested answers",
      clinical_case_id: @clinical_case_one.id,
      answers_attributes: [ { text: "Answer 1", is_correct: true } ]
    }
    question = Question.new(attributes)
    assert question.save, "Failed to save Q with CC and nested answers: #{question.errors.full_messages.join(", ")}"
    assert_equal 1, question.answers.count
  end

  test "can accept and create nested answers for standalone question with category" do
    attributes = {
      text: "Standalone Q with category and nested answers",
      category_id: @category_one.id,
      answers_attributes: [ { text: "Answer SA 1", is_correct: true } ]
    }
    question = Question.new(attributes)
    assert question.save, "Failed to save standalone Q with category and nested answers: #{question.errors.full_messages.join(", ")}"
    assert_equal 1, question.answers.count
  end

  # effective_category method
  test "effective_category returns category from clinical_case if present" do
    question = Question.new(text: "Q with CC", clinical_case: @clinical_case_one) # clinical_case_one belongs to category_one
    assert_equal @category_one, question.effective_category
  end

  test "effective_category returns direct category if question is standalone" do
    question = Question.new(text: "Standalone Q", category: @category_two)
    assert_equal @category_two, question.effective_category
  end

  test "effective_category returns nil if no category information (though validation should prevent this state)" do
    question = Question.new(text: "Q without any category info")
    # This state should be invalid due to model validations, but testing method's robustness
    assert_nil question.effective_category
  end

  # Scopes
  setup do
    # Clear out questions for cleaner scope testing if necessary, or ensure unique data
    Question.destroy_all

    @cat_scope_a = categories(:one) # Re-using fixture category
    @cat_scope_b = categories(:two) # Re-using fixture category

    @cc_scope_a1 = ClinicalCase.create!(name: "CC A1", category: @cat_scope_a, description: "d")
    @cc_scope_b1 = ClinicalCase.create!(name: "CC B1", category: @cat_scope_b, description: "d")

    # Questions associated with clinical cases
    @q_cc_a1 = Question.create!(text: "Q in CC A1 (Cat A)", clinical_case: @cc_scope_a1)
    @q_cc_a2 = Question.create!(text: "Q2 in CC A1 (Cat A)", clinical_case: @cc_scope_a1)
    @q_cc_b1 = Question.create!(text: "Q in CC B1 (Cat B)", clinical_case: @cc_scope_b1)

    # Standalone questions
    @q_sa_a = Question.create!(text: "Standalone Q in Cat A", category: @cat_scope_a)
    @q_sa_b = Question.create!(text: "Standalone Q in Cat B", category: @cat_scope_b)

    @player_scope = players(:player_one)
    # Make @q_cc_a1 practiced by @player_scope
    ans_for_practiced = Answer.create!(question: @q_cc_a1, text: "Ans for practiced", is_correct: true)
    PlayerAnswer.create!(player: @player_scope, question: @q_cc_a1, answer: ans_for_practiced)
  end

  test "with_clinical_case scope returns only questions associated with a clinical case" do
    questions_with_case = Question.with_clinical_case
    assert_includes questions_with_case, @q_cc_a1
    assert_includes questions_with_case, @q_cc_a2
    assert_includes questions_with_case, @q_cc_b1
    assert_not_includes questions_with_case, @q_sa_a
    assert_not_includes questions_with_case, @q_sa_b
    assert_equal 3, questions_with_case.count
  end

  test "standalone scope returns only questions not associated with a clinical case (i.e., direct category)" do
    standalone_questions = Question.standalone
    assert_includes standalone_questions, @q_sa_a
    assert_includes standalone_questions, @q_sa_b
    assert_not_includes standalone_questions, @q_cc_a1
    assert_not_includes standalone_questions, @q_cc_a2
    assert_not_includes standalone_questions, @q_cc_b1
    assert_equal 2, standalone_questions.count
  end

  test "by_category scope filters questions by category_id (both via clinical_case and direct)" do
    questions_in_cat_a = Question.by_category(@cat_scope_a.id)
    assert_includes questions_in_cat_a, @q_cc_a1, "Should include Q from CC in Cat A"
    assert_includes questions_in_cat_a, @q_cc_a2, "Should include Q2 from CC in Cat A"
    assert_includes questions_in_cat_a, @q_sa_a,  "Should include Standalone Q in Cat A"
    assert_not_includes questions_in_cat_a, @q_cc_b1, "Should not include Q from CC in Cat B"
    assert_not_includes questions_in_cat_a, @q_sa_b,  "Should not include Standalone Q in Cat B"
    assert_equal 3, questions_in_cat_a.count

    questions_in_cat_b = Question.by_category(@cat_scope_b.id)
    assert_includes questions_in_cat_b, @q_cc_b1
    assert_includes questions_in_cat_b, @q_sa_b
    assert_not_includes questions_in_cat_b, @q_cc_a1
    assert_not_includes questions_in_cat_b, @q_sa_a
    assert_equal 2, questions_in_cat_b.count
  end

  test "by_clinical_case scope filters questions by clinical_case_id" do
    questions_in_cc_a1 = Question.by_clinical_case(@cc_scope_a1.id)
    assert_includes questions_in_cc_a1, @q_cc_a1
    assert_includes questions_in_cc_a1, @q_cc_a2
    assert_not_includes questions_in_cc_a1, @q_cc_b1
    assert_equal 2, questions_in_cc_a1.count
  end

  test "not_practiced_by scope returns questions not practiced by a given player" do
    # @player_scope has practiced @q_cc_a1.
    # Expected not practiced: @q_cc_a2, @q_cc_b1, @q_sa_a, @q_sa_b
    not_practiced_list = Question.not_practiced_by(@player_scope)

    assert_includes not_practiced_list, @q_cc_a2
    assert_includes not_practiced_list, @q_cc_b1
    assert_includes not_practiced_list, @q_sa_a
    assert_includes not_practiced_list, @q_sa_b
    assert_not_includes not_practiced_list, @q_cc_a1

    assert_equal 4, not_practiced_list.count
  end
end

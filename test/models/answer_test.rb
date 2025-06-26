require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  fixtures :categories, :clinical_cases, :questions, :answers, :players
  # Test associations
  test "should belong to question" do
    answer = Answer.new
    assert_respond_to answer, :question
    assert_respond_to answer, :question_id # Check for foreign key presence too
  end

  test "should have many player_answers" do
    answer = Answer.new
    assert_respond_to answer, :player_answers
  end

  # Test attributes existence (basic check)
  test "should respond to text attribute" do
    assert_respond_to Answer.new, :text
  end

  test "should respond to description attribute" do
    assert_respond_to Answer.new, :description
  end

  test "should respond to is_correct attribute" do
    assert_respond_to Answer.new, :is_correct
  end

  # Setup for tests needing fixture data
  setup do
    @category_one = categories(:one)
    @clinical_case_one = clinical_cases(:one) # Assumes this belongs to @category_one
    @question_one = questions(:one) # Assumes this belongs to @clinical_case_one
    @answer_one = answers(:one) # Assumes this is for @question_one
    @player_one = players(:player_one)
    @player_two = players(:player_two)

    # Ensure fixture consistency if needed, e.g., @answer_one belongs to @question_one
    if @answer_one.question != @question_one
        @answer_one.update!(question: @question_one)
    end
    if @question_one.clinical_case != @clinical_case_one
        @question_one.update!(clinical_case: @clinical_case_one)
    end
    if @clinical_case_one.category != @category_one
        @clinical_case_one.update!(category: @category_one)
    end
  end

  test "should be valid with valid attributes (text, is_correct, question)" do
    # Create a new question for this test to avoid conflicts with other tests using @question_one
    new_question_for_valid_answer = Question.create!(text: "New Q for Valid Answer Test", clinical_case: @clinical_case_one)

    answer = Answer.new(
      text: "A valid answer text",
      description: "An optional detailed description of the answer.",
      is_correct: true,
      question: new_question_for_valid_answer # Associate with the new question
    )
    assert answer.valid?, "Answer should be valid but had errors: #{answer.errors.full_messages.join(", ")}"
    assert answer.save, "Failed to save a valid answer."
  end

  test "is_correct attribute should allow true, false, or nil values" do
    question_for_correctness = Question.create!(text: "Q for Correctness Test", clinical_case: @clinical_case_one)

    answer_true = Answer.new(text: "This Answer is True", question: question_for_correctness, is_correct: true)
    assert answer_true.valid?, "Answer with is_correct:true should be valid. Errors: #{answer_true.errors.full_messages.join(", ")}"
    assert answer_true.save
    assert_equal true, answer_true.reload.is_correct

    answer_false = Answer.new(text: "This Answer is False", question: question_for_correctness, is_correct: false)
    assert answer_false.valid?, "Answer with is_correct:false should be valid. Errors: #{answer_false.errors.full_messages.join(", ")}"
    assert answer_false.save
    assert_equal false, answer_false.reload.is_correct

    # Schema for Answer: t.boolean "is_correct" (does not specify NOT NULL or a default)
    # So, nil should be permissible by the database if no model validation prevents it.
    answer_nil_correctness = Answer.new(text: "This Answer has Nil Correctness", question: question_for_correctness, is_correct: nil)
    assert answer_nil_correctness.valid?, "Answer with is_correct:nil should be valid. Errors: #{answer_nil_correctness.errors.full_messages.join(", ")}"
    assert answer_nil_correctness.save
    assert_nil answer_nil_correctness.reload.is_correct
  end

  test "can have multiple player_answers from different players for the same question" do
    # Use @answer_one which is associated with @question_one
    # Player one answers with @answer_one
    PlayerAnswer.create!(player: @player_one, question: @question_one, answer: @answer_one)

    # Player two answers the same question (@question_one) also choosing @answer_one
    PlayerAnswer.create!(player: @player_two, question: @question_one, answer: @answer_one)

    # Reload @answer_one to get its player_answers association updated from DB
    @answer_one.reload
    assert_equal 2, @answer_one.player_answers.count, "Answer should have 2 player_answers"
    # More specific check if PlayerAnswer stores question_id (which it does)
    assert_equal 2, @answer_one.player_answers.where(question_id: @question_one.id).count
  end

  test "should not be valid without being associated with a question" do
    answer = Answer.new(text: "Orphaned Answer", is_correct: true) # No question_id provided
    assert_not answer.valid?, "Answer should be invalid if not associated with a question."
    assert_includes answer.errors[:question], "must exist" # `belongs_to` adds this validation
  end

  test "text attribute can be nil (if schema allows and no model validation)" do
    # Answer model schema: t.string "text" (does not specify NOT NULL)
    # Answer model itself does not have `validates :text, presence: true`
    # So, nil text should be permissible.

    # Use a new question for this specific test
    q_for_nil_text_ans = Question.create!(text: "Q for Nil Text Answer", clinical_case: @clinical_case_one)

    answer_with_nil_text = Answer.new(
      question: q_for_nil_text_ans,
      is_correct: false,
      description: "This answer has nil text but a description."
      # text attribute is implicitly nil here
    )
    assert answer_with_nil_text.valid?,
           "Answer with nil text should be valid if no model validation for text presence. Errors: #{answer_with_nil_text.errors.full_messages.join(", ")}"

    assert answer_with_nil_text.save
    answer_with_nil_text.reload
    assert_nil answer_with_nil_text.text

    # Should also be valid if text is later provided
    answer_with_nil_text.text = "Not nil anymore"
    assert answer_with_nil_text.valid?, "Answer should be valid once text is provided."
  end

  test "description attribute can be nil" do
    # Answer model schema: t.text "description" (nullable by default)
    q_for_nil_desc_ans = Question.create!(text: "Q for Nil Desc Answer", clinical_case: @clinical_case_one)
    answer_with_nil_desc = Answer.new(
        question: q_for_nil_desc_ans,
        text: "Answer with text but nil description",
        is_correct: true
      # description is implicitly nil
    )
    assert answer_with_nil_desc.valid?, "Answer with nil description should be valid. Errors: #{answer_with_nil_desc.errors.full_messages.join(", ")}"
    assert answer_with_nil_desc.save
    assert_nil answer_with_nil_desc.reload.description
  end
end

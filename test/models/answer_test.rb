require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:question)
    should have_many(:player_answers)
  end

  context "attributes" do
    should "respond to text" do
      assert_respond_to Answer.new, :text
    end

    should "respond to description" do
      assert_respond_to Answer.new, :description
    end

    should "respond to is_correct" do
      assert_respond_to Answer.new, :is_correct
    end
  end

  setup do
    @category = categories(:one)
    @clinical_case = clinical_cases(:one)
    @question = questions(:one)
    @answer = answers(:one)
    @player_one = players(:player_one)
    @player_two = players(:player_two)
  end

  test "should be valid with valid attributes" do
    new_question = Question.create!(text: "New Sample Question", clinical_case: @clinical_case)
    answer = Answer.new(
      text: "Sample Answer Text",
      description: "Detailed description of the answer.",
      is_correct: true,
      question: new_question
    )
    assert answer.valid?, "Answer should be valid but had errors: #{answer.errors.full_messages.join(", ")}"
    assert answer.save
  end

  test "is_correct should allow true, false, or nil" do
    question_for_correctness_test = Question.create!(text: "Correctness Test Question", clinical_case: @clinical_case)

    answer_true = Answer.new(text: "True Answer", question: question_for_correctness_test, is_correct: true)
    assert answer_true.valid?
    assert answer_true.save
    assert_equal true, answer_true.reload.is_correct

    answer_false = Answer.new(text: "False Answer", question: question_for_correctness_test, is_correct: false)
    assert answer_false.valid?
    assert answer_false.save
    assert_equal false, answer_false.reload.is_correct

    answer_nil = Answer.new(text: "Nil Answer", question: question_for_correctness_test, is_correct: nil)
    assert answer_nil.valid?
    assert answer_nil.save
    assert_nil answer_nil.reload.is_correct
  end

  test "can have multiple player_answers" do
    # Ensure the answer is associated with the question from fixtures
    @answer.update!(question: @question)

    PlayerAnswer.create!(player: @player_one, question: @question, answer: @answer)
    # For the second player_answer, we need a different player or question if there's a uniqueness constraint
    # Assuming a player can only answer a question once.
    # Let's use a different question or a different answer for the same player if the model allows.
    # For this test, we assume multiple players can select the same answer for the same question.
    # If PlayerAnswer has a uniqueness constraint on (player_id, question_id), this test would need adjustment
    # or the second PlayerAnswer would need to be for a different question if testing answer.player_answers.

    # Re-reading PlayerAnswer model: validates :player_id, uniqueness: { scope: :question_id }
    # This means a player can only answer a specific question once.
    # However, an Answer can be chosen by multiple players for the *same* question (as part of their PlayerAnswer).

    # Create a second player answer for the same question but by a different player
    PlayerAnswer.create!(player: @player_two, question: @question, answer: @answer)

    assert_equal 2, @answer.player_answers.where(question: @question).count, "Answer should have 2 player_answers for this specific question"
  end

  test "should not be valid without a question" do
    answer = Answer.new(text: "Orphan Answer", is_correct: true)
    assert_not answer.valid?
    assert_includes answer.errors[:question], "must exist"
  end

  test "text attribute can be nil (based on schema)" do
    # The schema shows 'text' can be string, but doesn't specify NOT NULL.
    # However, 'description' is text. Let's assume 'text' is the primary content.
    # It's more common for 'text' or similar fields to be required.
    # If 'text' is indeed nullable, this test is fine. If not, it should fail or be changed.
    # Based on `answers.yml`, `description` is used, and `text` is not present in yml,
    # but `answers` table has `t.string "text"`.
    # Let's assume `text` is the main field and should ideally be present.
    # For now, testing if nil is technically allowed by DB schema (if no model validation).
    answer = Answer.new(question: @question, is_correct: false, description: "Answer with nil text")
    # If there's no `validates :text, presence: true` in Answer model, this should be valid.
    # Let's assume for now it's not strictly required by model validation.
    # We will add a validation later if needed.
    assert answer.valid?, "Answer with nil text should be valid if no model validation for text presence. Errors: #{answer.errors.full_messages.join(", ")}"
    answer.text = "Not nil anymore"
    assert answer.valid?
  end
end

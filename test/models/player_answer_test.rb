require "test_helper"

class PlayerAnswerTest < ActiveSupport::TestCase
  # Associations
  test "should belong to player" do
    pa = PlayerAnswer.new
    assert_respond_to pa, :player
    assert_respond_to pa, :player_id
  end

  test "should belong to question" do
    pa = PlayerAnswer.new
    assert_respond_to pa, :question
    assert_respond_to pa, :question_id
  end

  test "should belong to answer" do
    pa = PlayerAnswer.new
    assert_respond_to pa, :answer
    assert_respond_to pa, :answer_id
  end

  # Validations
  setup do
    # For uniqueness validation (player_id scoped to question_id) and general tests
    @player_one = players(:player_one)
    @question_one = questions(:one)
    @answer_one_for_q_one = answers(:one) # Assuming this is for @question_one and correct

    # Ensure answer_one_for_q_one is actually for @question_one
    if @answer_one_for_q_one.question != @question_one
      @answer_one_for_q_one.update!(question: @question_one)
    end

    # Create an existing PlayerAnswer for uniqueness testing
    PlayerAnswer.find_or_create_by!(player: @player_one, question: @question_one) do |pa_setup|
      pa_setup.answer = @answer_one_for_q_one
    end

    # Other fixtures for varied tests
    @player_two = players(:player_two)
    @question_two = questions(:two)
    @answer_three_for_q_two = answers(:three) # Assuming this is for @question_two and correct
     if @answer_three_for_q_two.question != @question_two
      @answer_three_for_q_two.update!(question: @question_two)
    end
  end

  test "should be invalid without a player" do
    pa = PlayerAnswer.new(question: @question_one, answer: @answer_one_for_q_one)
    assert_not pa.valid?, "PlayerAnswer should be invalid without a player"
    assert_includes pa.errors[:player], "must exist"
  end

  test "should be invalid without a question" do
    pa = PlayerAnswer.new(player: @player_one, answer: @answer_one_for_q_one)
    assert_not pa.valid?, "PlayerAnswer should be invalid without a question"
    assert_includes pa.errors[:question], "must exist"
  end

  test "should be invalid without an answer" do
    pa = PlayerAnswer.new(player: @player_one, question: @question_one)
    assert_not pa.valid?, "PlayerAnswer should be invalid without an answer"
    assert_includes pa.errors[:answer], "must exist"
  end

  test "player_id must be unique scoped to question_id" do
    # A PlayerAnswer for @player_one and @question_one was created in setup.
    # Try to create another one with a different answer for the same player and question.
    another_answer_for_q_one = Answer.create!(question: @question_one, text: "Alternative Answer for Q1", is_correct: false)

    duplicate_pa = PlayerAnswer.new(
      player: @player_one,
      question: @question_one, # Same player, same question
      answer: another_answer_for_q_one
    )
    assert_not duplicate_pa.valid?, "Should not be valid due to (player_id, question_id) uniqueness"
    assert_includes duplicate_pa.errors[:player_id], "ya ha respondido esta pregunta"
  end

  # Callbacks: before_create :set_correctness
  test "set_correctness callback sets is_correct based on chosen answer's correctness" do
    # Use a new player/question to avoid uniqueness conflicts from setup
    player_cb = Player.create!(facebook_id: "fb_pa_cb_#{SecureRandom.hex(3)}")
    question_cb = Question.create!(text: "Q for PA CB", clinical_case: clinical_cases(:one))

    correct_answer = Answer.create!(question: question_cb, text: "CB Ans Correct", is_correct: true)
    pa_correct = PlayerAnswer.create!(player: player_cb, question: question_cb, answer: correct_answer)
    assert_equal true, pa_correct.is_correct, "is_correct should be true for correct answer"
    pa_correct.destroy # clean up to allow next PA for same player/question

    incorrect_answer = Answer.create!(question: question_cb, text: "CB Ans Incorrect", is_correct: false)
    pa_incorrect = PlayerAnswer.create!(player: player_cb, question: question_cb, answer: incorrect_answer)
    assert_equal false, pa_incorrect.is_correct, "is_correct should be false for incorrect answer"
    pa_incorrect.destroy

    nil_correct_answer = Answer.create!(question: question_cb, text: "CB Ans Nil Correct", is_correct: nil)
    pa_nil_correct = PlayerAnswer.create!(player: player_cb, question: question_cb, answer: nil_correct_answer)
    assert_nil pa_nil_correct.is_correct, "is_correct should be nil if answer.is_correct is nil"
  end

  # after_create :update_player_stats is commented out in model, so no test for it.

  # Scopes
  def setup_for_scope_tests
    PlayerAnswer.delete_all # Clean slate for precise scope testing

    @player_s = Player.create!(facebook_id: "fb_pa_scope_#{SecureRandom.hex(3)}")
    @q_s1 = Question.create!(text: "Scope Q1 PA", clinical_case: clinical_cases(:one))
    @q_s2 = Question.create!(text: "Scope Q2 PA", clinical_case: clinical_cases(:one))
    @q_s3 = Question.create!(text: "Scope Q3 PA", clinical_case: clinical_cases(:one))


    @ans_s1_correct = Answer.create!(question: @q_s1, text: "S1 Correct", is_correct: true)
    @ans_s2_incorrect = Answer.create!(question: @q_s2, text: "S2 Incorrect", is_correct: false)
    @ans_s3_correct_old = Answer.create!(question: @q_s3, text: "S3 Correct Old", is_correct: true) # another correct one

    @pa_correct_recent = PlayerAnswer.create!(player: @player_s, question: @q_s1, answer: @ans_s1_correct, created_at: Time.now)
    @pa_incorrect_less_recent = PlayerAnswer.create!(player: @player_s, question: @q_s2, answer: @ans_s2_incorrect, created_at: 30.minutes.ago)
    @pa_correct_old = PlayerAnswer.create!(player: @player_s, question: @q_s3, answer: @ans_s3_correct_old, created_at: 1.day.ago)
  end

  test "correct scope returns only correct player_answers" do
    setup_for_scope_tests
    correct_answers = PlayerAnswer.correct
    assert_includes correct_answers, @pa_correct_recent
    assert_includes correct_answers, @pa_correct_old
    assert_not_includes correct_answers, @pa_incorrect_less_recent
    assert_equal 2, correct_answers.count
  end

  test "incorrect scope returns only incorrect player_answers" do
    setup_for_scope_tests
    incorrect_answers = PlayerAnswer.incorrect
    assert_includes incorrect_answers, @pa_incorrect_less_recent
    assert_not_includes incorrect_answers, @pa_correct_recent
    assert_not_includes incorrect_answers, @pa_correct_old
    assert_equal 1, incorrect_answers.count
  end

  test "recent scope orders player_answers by creation date descending" do
    setup_for_scope_tests
    # Order: @pa_correct_recent, @pa_incorrect_less_recent, @pa_correct_old
    recent_pas = PlayerAnswer.where(player: @player_s).recent.to_a # Filter by player for this test
    expected_order = [@pa_correct_recent, @pa_incorrect_less_recent, @pa_correct_old]
    assert_equal expected_order.map(&:id), recent_pas.map(&:id)
  end

  test "by_question scope filters answers by question_id" do
    setup_for_scope_tests
    answers_for_q_s1 = PlayerAnswer.by_question(@q_s1.id)
    assert_includes answers_for_q_s1, @pa_correct_recent
    assert_equal 1, answers_for_q_s1.count

    answers_for_q_s2 = PlayerAnswer.by_question(@q_s2.id)
    assert_includes answers_for_q_s2, @pa_incorrect_less_recent
    assert_equal 1, answers_for_q_s2.count
  end

  # General validity and attributes
  test "should be valid with all required associations and attributes" do
    # Use a player/question combo not used in setup to avoid uniqueness issues
    pa = PlayerAnswer.new(
      player: @player_two,
      question: @question_two,
      answer: @answer_three_for_q_two, # This is for @question_two
      time_taken: 120,
      mode: "practice" # Default is 'practice'
    )
    assert pa.valid?, pa.errors.full_messages.join(", ")
  end

  test "time_taken attribute can be nil" do
    pa = PlayerAnswer.new(player: @player_two, question: @question_two, answer: @answer_three_for_q_two, time_taken: nil)
    assert pa.valid?, "PA with nil time_taken should be valid. Errors: #{pa.errors.full_messages.join(", ")}"
    assert pa.save
    assert_nil pa.reload.time_taken
  end

  test "mode attribute defaults to 'practice'" do
    # Create with a unique player/question pair for saving
    p_mode = Player.create!(facebook_id: "fb_pa_mode_def_#{SecureRandom.hex(3)}")
    q_mode = Question.create!(text: "Q mode default", clinical_case: clinical_cases(:one))
    a_mode = Answer.create!(question: q_mode, text: "A mode default", is_correct: true)

    pa = PlayerAnswer.new(player: p_mode, question: q_mode, answer: a_mode)
    # Default is applied by DB or AR upon initialization/save.
    assert pa.save
    assert_equal "practice", pa.reload.mode
  end

  test "mode attribute can be set to other string values" do
    p_mode_set = Player.create!(facebook_id: "fb_pa_mode_set_#{SecureRandom.hex(3)}")
    q_mode_set = Question.create!(text: "Q mode set", clinical_case: clinical_cases(:one))
    a_mode_set = Answer.create!(question: q_mode_set, text: "A mode set", is_correct: true)

    custom_mode = "assessment_mode"
    pa = PlayerAnswer.new(player: p_mode_set, question: q_mode_set, answer: a_mode_set, mode: custom_mode)
    assert pa.save
    assert_equal custom_mode, pa.reload.mode
  end
end

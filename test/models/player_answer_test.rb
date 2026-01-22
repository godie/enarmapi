require "test_helper"

class PlayerAnswerTest < ActiveSupport::TestCase
  fixtures :users, :categories, :questions, :answers, :clinical_cases

  # Associations
  test "should belong to user" do
    ua = UserAnswer.new
    assert_respond_to ua, :user
    assert_respond_to ua, :user_id
  end

  test "should belong to question" do
    ua = UserAnswer.new
    assert_respond_to ua, :question
    assert_respond_to ua, :question_id
  end

  test "should belong to answer" do
    ua = UserAnswer.new
    assert_respond_to ua, :answer
    assert_respond_to ua, :answer_id
  end

  # Validations
  setup do
    # For uniqueness validation (user_id scoped to question_id) and general tests
    @player_one = users(:player_one)
    @question_one = questions(:one)
    @answer_one_for_q_one = answers(:one) # Assuming this is for @question_one and correct

    # Ensure answer_one_for_q_one is actually for @question_one
    if @answer_one_for_q_one.question != @question_one
      @answer_one_for_q_one.update!(question: @question_one)
    end

    # Create an existing UserAnswer for uniqueness testing
    UserAnswer.find_or_create_by!(user: @player_one, question: @question_one) do |ua_setup|
      ua_setup.answer = @answer_one_for_q_one
    end

    # Other fixtures for varied tests
    @player_two = users(:player_two)
    @question_two = questions(:two)
    @answer_three_for_q_two = answers(:three) # Assuming this is for @question_two and correct
     if @answer_three_for_q_two.question != @question_two
      @answer_three_for_q_two.update!(question: @question_two)
     end
  end

  test "should be invalid without a user" do
    ua = UserAnswer.new(question: @question_one, answer: @answer_one_for_q_one)
    assert_not ua.valid?, "UserAnswer should be invalid without a user"
    assert_includes ua.errors[:user], "must exist"
  end

  test "should be invalid without a question" do
    ua = UserAnswer.new(user: @player_one, answer: @answer_one_for_q_one)
    assert_not ua.valid?, "UserAnswer should be invalid without a question"
    assert_includes ua.errors[:question], "must exist"
  end

  test "should be invalid without an answer" do
    ua = UserAnswer.new(user: @player_one, question: @question_one)
    assert_not ua.valid?, "UserAnswer should be invalid without an answer"
    assert_includes ua.errors[:answer], "must exist"
  end

  test "user_id can have multiple answers for the same question (no uniqueness validation)" do
    # Note: UserAnswer model does not have a uniqueness validation for (user_id, question_id)
    # This allows users to answer the same question multiple times
    # A UserAnswer for @player_one and @question_one was created in setup.
    # Try to create another one with a different answer for the same user and question.
    another_answer_for_q_one = Answer.create!(question: @question_one, text: "Alternative Answer for Q1", is_correct: false)

    duplicate_ua = UserAnswer.new(
      user: @player_one,
      question: @question_one, # Same user, same question
      answer: another_answer_for_q_one
    )
    # Since there's no uniqueness validation, this should be valid
    assert duplicate_ua.valid?, "Should be valid - no uniqueness constraint. Errors: #{duplicate_ua.errors.full_messages.join(", ")}"
    assert duplicate_ua.save, "Should be able to save multiple answers for same user and question"
  end

  # Callbacks: before_create :set_correctness
  test "set_correctness callback sets is_correct based on chosen answer's correctness" do
    # Use a new user/question to avoid uniqueness conflicts from setup
    user_cb = User.create!(facebook_id: "fb_pa_cb_#{SecureRandom.hex(3)}", email: "cb@example.com", role: :player)
    question_cb = Question.create!(text: "Q for UA CB", clinical_case: clinical_cases(:one))

    correct_answer = Answer.create!(question: question_cb, text: "CB Ans Correct", is_correct: true)
    ua_correct = UserAnswer.create!(user: user_cb, question: question_cb, answer: correct_answer)
    assert_equal true, ua_correct.is_correct, "is_correct should be true for correct answer"
    ua_correct.destroy # clean up to allow next UA for same user/question

    incorrect_answer = Answer.create!(question: question_cb, text: "CB Ans Incorrect", is_correct: false)
    ua_incorrect = UserAnswer.create!(user: user_cb, question: question_cb, answer: incorrect_answer)
    assert_equal false, ua_incorrect.is_correct, "is_correct should be false for incorrect answer"
    ua_incorrect.destroy

    nil_correct_answer = Answer.create!(question: question_cb, text: "CB Ans Nil Correct", is_correct: nil)
    ua_nil_correct = UserAnswer.create!(user: user_cb, question: question_cb, answer: nil_correct_answer)
    assert_equal false, ua_nil_correct.is_correct, "is_correct should be false if answer.is_correct insert is nil"
  end

  # after_create :update_player_stats is commented out in model, so no test for it.

  # Scopes
  def setup_for_scope_tests
    UserAnswer.delete_all # Clean slate for precise scope testing

    @user_s = User.create!(facebook_id: "fb_pa_scope_#{SecureRandom.hex(3)}", email: "scope@example.com", role: :player)
    @q_s1 = Question.create!(text: "Scope Q1 UA", clinical_case: clinical_cases(:one))
    @q_s2 = Question.create!(text: "Scope Q2 UA", clinical_case: clinical_cases(:one))
    @q_s3 = Question.create!(text: "Scope Q3 UA", clinical_case: clinical_cases(:one))


    @ans_s1_correct = Answer.create!(question: @q_s1, text: "S1 Correct", is_correct: true)
    @ans_s2_incorrect = Answer.create!(question: @q_s2, text: "S2 Incorrect", is_correct: false)
    @ans_s3_correct_old = Answer.create!(question: @q_s3, text: "S3 Correct Old", is_correct: true) # another correct one

    @ua_correct_recent = UserAnswer.create!(user: @user_s, question: @q_s1, answer: @ans_s1_correct, created_at: Time.now)
    @ua_incorrect_less_recent = UserAnswer.create!(user: @user_s, question: @q_s2, answer: @ans_s2_incorrect, created_at: 30.minutes.ago)
    @ua_correct_old = UserAnswer.create!(user: @user_s, question: @q_s3, answer: @ans_s3_correct_old, created_at: 1.day.ago)
  end

  test "correct scope returns only correct user_answers" do
    setup_for_scope_tests
    correct_answers = UserAnswer.correct
    assert_includes correct_answers, @ua_correct_recent
    assert_includes correct_answers, @ua_correct_old
    assert_not_includes correct_answers, @ua_incorrect_less_recent
    assert_equal 2, correct_answers.count
  end

  test "incorrect scope returns only incorrect user_answers" do
    setup_for_scope_tests
    incorrect_answers = UserAnswer.incorrect
    assert_includes incorrect_answers, @ua_incorrect_less_recent
    assert_not_includes incorrect_answers, @ua_correct_recent
    assert_not_includes incorrect_answers, @ua_correct_old
    assert_equal 1, incorrect_answers.count
  end

  test "recent scope orders user_answers by creation date descending" do
    setup_for_scope_tests
    # Order: @ua_correct_recent, @ua_incorrect_less_recent, @ua_correct_old
    recent_uas = UserAnswer.where(user: @user_s).recent.to_a # Filter by user for this test
    expected_order = [ @ua_correct_recent, @ua_incorrect_less_recent, @ua_correct_old ]
    assert_equal expected_order.map(&:id), recent_uas.map(&:id)
  end

  test "by_question scope filters answers by question_id" do
    setup_for_scope_tests
    answers_for_q_s1 = UserAnswer.by_question(@q_s1.id)
    assert_includes answers_for_q_s1, @ua_correct_recent
    assert_equal 1, answers_for_q_s1.count

    answers_for_q_s2 = UserAnswer.by_question(@q_s2.id)
    assert_includes answers_for_q_s2, @ua_incorrect_less_recent
    assert_equal 1, answers_for_q_s2.count
  end

  # General validity and attributes
  test "should be valid with all required associations and attributes" do
    # Use a user/question combo not used in setup to avoid uniqueness issues
    ua = UserAnswer.new(
      user: @player_two,
      question: @question_two,
      answer: @answer_three_for_q_two, # This is for @question_two
      time_taken: 120,
      mode: "practice" # Default is 'practice'
    )
    assert ua.valid?, ua.errors.full_messages.join(", ")
  end

  test "time_taken attribute can be nil" do
    ua = UserAnswer.new(user: @player_two, question: @question_two, answer: @answer_three_for_q_two, time_taken: nil)
    assert ua.valid?, "UA with nil time_taken should be valid. Errors: #{ua.errors.full_messages.join(", ")}"
    assert ua.save
    assert_nil ua.reload.time_taken
  end

  test "mode attribute defaults to 'practice'" do
    # Create with a unique user/question pair for saving
    u_mode = User.create!(facebook_id: "fb_pa_mode_def_#{SecureRandom.hex(3)}", email: "mode@example.com", role: :player)
    q_mode = Question.create!(text: "Q mode default", clinical_case: clinical_cases(:one))
    a_mode = Answer.create!(question: q_mode, text: "A mode default", is_correct: true)

    ua = UserAnswer.new(user: u_mode, question: q_mode, answer: a_mode)
    # Default is applied by DB or AR upon initialization/save.
    assert ua.save
    assert_equal "practice", ua.reload.mode
  end

  test "mode attribute can be set to other string values" do
    u_mode_set = User.create!(facebook_id: "fb_pa_mode_set_#{SecureRandom.hex(3)}", email: "modeset@example.com", role: :player)
    q_mode_set = Question.create!(text: "Q mode set", clinical_case: clinical_cases(:one))
    a_mode_set = Answer.create!(question: q_mode_set, text: "A mode set", is_correct: true)

    custom_mode = "assessment_mode"
    ua = UserAnswer.new(user: u_mode_set, question: q_mode_set, answer: a_mode_set, mode: custom_mode)
    assert ua.save
    assert_equal custom_mode, ua.reload.mode
  end
end

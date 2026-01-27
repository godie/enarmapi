require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  fixtures :users, :categories
  # Associations - testing User with role: player
  test "should have many user_answers" do
    player = User.new(role: :player, email: "test@example.com", facebook_id: "fb_test")
    assert_respond_to player, :user_answers
  end

  test "should have many practiced_questions through user_answers" do
    player = User.new(role: :player, email: "test@example.com", facebook_id: "fb_test")
    assert_respond_to player, :practiced_questions
  end

  test "should have many answers (chosen by user) through user_answers" do
    player = User.new(role: :player, email: "test@example.com", facebook_id: "fb_test")
    assert_respond_to player, :answers # These are the Answer records chosen in UserAnswers
  end

  test "should have many user_exams" do
    player = User.new(role: :player, email: "test@example.com", facebook_id: "fb_test")
    assert_respond_to player, :user_exams
  end

  test "should have many taken_exams through user_exams" do
    player = User.new(role: :player, email: "test@example.com", facebook_id: "fb_test")
    assert_respond_to player, :taken_exams
  end

  # Validations
  setup do
    # For uniqueness validation of facebook_id
    # users(:player_one) has facebook_id "fb_player_fixture_one_unique_id"
    User.find_or_create_by!(facebook_id: users(:player_one).facebook_id) do |p_setup|
      p_setup.name = users(:player_one).name
      p_setup.email = users(:player_one).email
      p_setup.role = :player
    end
  end

  test "facebook_id should be unique if present" do
    existing_fb_id = users(:player_one).facebook_id # This was created in setup
    player = User.new(facebook_id: existing_fb_id, email: "different@example.com", role: :player)
    assert_not player.valid?, "User facebook_id should be unique"
    assert_includes player.errors[:facebook_id], "has already been taken"
  end

  test "email should allow valid formats" do
    player_valid_email = User.new(facebook_id: "fb_email_test_#{SecureRandom.hex(3)}", role: :player)

    valid_emails = [ "user@example.com", "USER@example.com", "a.user.name@subdomain.example.co.uk" ]
    valid_emails.each do |email|
      player_valid_email.email = email
      assert player_valid_email.valid?, "#{email.inspect} should be a valid email. Errors: #{player_valid_email.errors.full_messages.join(", ")}"
    end

    invalid_emails = [ "user@example", "user_at_example.com", "user@.com" ]
    invalid_emails.each do |email|
      player_valid_email.email = email
      assert_not player_valid_email.valid?, "#{player_valid_email.email.inspect} should be an invalid email format."
      assert_includes player_valid_email.errors[:email], "is invalid"
    end
  end

  test "name can be nil (schema allows, no model validation)" do
    player = User.new(facebook_id: "fb_nil_name_test_#{SecureRandom.hex(4)}", email: "test@example.com", role: :player)
    assert player.valid?, "User should be valid with a nil name. Errors: #{player.errors.full_messages.join(", ")}"
    assert player.save
    assert_nil player.reload.name
  end

  # General setup for instance method tests
  # This setup is more specific to instance method tests rather than a global one.
  def setup_for_instance_methods
    @player_for_methods = User.create!(facebook_id: "fb_methods_test_#{SecureRandom.hex(4)}", email: "methods@example.com", role: :player)

    @category = categories(:one)
    @clinical_case = ClinicalCase.find_or_create_by!(name: "CC for Player Methods", category: @category, description: "d")

    @q1_methods = Question.find_or_create_by!(text: "Q1 Player Methods", clinical_case: @clinical_case)
    @q2_methods = Question.find_or_create_by!(text: "Q2 Player Methods", clinical_case: @clinical_case)
    @q3_methods = Question.find_or_create_by!(text: "Q3 Player Methods", clinical_case: @clinical_case)


    @ans_q1_correct = Answer.find_or_create_by!(question: @q1_methods, text: "Ans Q1 Correct", is_correct: true)
    @ans_q1_incorrect = Answer.find_or_create_by!(question: @q1_methods, text: "Ans Q1 Incorrect", is_correct: false)
    @ans_q2_correct = Answer.find_or_create_by!(question: @q2_methods, text: "Ans Q2 Correct", is_correct: true)
    @ans_q2_incorrect = Answer.find_or_create_by!(question: @q2_methods, text: "Ans Q2 Incorrect", is_correct: false)
    @ans_q3_correct = Answer.find_or_create_by!(question: @q3_methods, text: "Ans Q3 Correct", is_correct: true)
  end

  # Instance Methods
  test "#stats returns correct statistics hash" do
    setup_for_instance_methods
    # Create UserAnswers for @player_for_methods
    # Correct answer for Q1
    UserAnswer.create!(user: @player_for_methods, question: @q1_methods, answer: @ans_q1_correct, time_taken: 10)
    # Incorrect answer for Q2
    UserAnswer.create!(user: @player_for_methods, question: @q2_methods, answer: @ans_q2_incorrect, time_taken: 20)
    # Correct answer for Q3
    UserAnswer.create!(user: @player_for_methods, question: @q3_methods, answer: @ans_q3_correct, time_taken: 15)
    @player_for_methods.reload

    stats = @player_for_methods.stats
    assert_kind_of Hash, stats
    assert_equal 3, stats[:total_answers], "Total answers count in stats is wrong"
    assert_equal 2, stats[:correct_answers], "Correct answers count in stats is wrong"
    assert_equal 1, stats[:incorrect_answers], "Incorrect answers count in stats is wrong"
    assert_equal ((2.0/3.0) * 100).round(2), stats[:accuracy_percentage], "Accuracy percentage in stats is wrong"
    assert_equal 3, stats[:questions_answered], "Distinct questions answered count in stats is wrong"
    assert_not_nil stats[:last_activity], "Last activity should be populated in stats"
  end

  test "#stats returns zero/nil for a user with no answers" do
    new_player_no_activity = User.create!(facebook_id: "fb_stats_no_activity_#{SecureRandom.hex(4)}", email: "noactivity@example.com", role: :player)
    stats = new_player_no_activity.stats
    assert_equal 0, stats[:total_answers]
    assert_equal 0, stats[:correct_answers]
    assert_equal 0, stats[:incorrect_answers]
    assert_equal 0, stats[:accuracy_percentage]
    assert_equal 0, stats[:questions_answered]
    assert_nil stats[:last_activity]
  end

  test "#calculate_accuracy returns correct percentage" do
    setup_for_instance_methods
    UserAnswer.create!(user: @player_for_methods, question: @q1_methods, answer: @ans_q1_correct) # Correct
    UserAnswer.create!(user: @player_for_methods, question: @q2_methods, answer: @ans_q2_incorrect) # Incorrect
    @player_for_methods.reload

    assert_equal 2, @player_for_methods.user_answers.count
    assert_equal 1, @player_for_methods.user_answers.correct.count
    assert_equal 50.0, @player_for_methods.calculate_accuracy
  end

  test "#calculate_accuracy returns 0 if no answers" do
    new_player_no_accuracy = User.create!(facebook_id: "fb_calc_acc_no_ans_#{SecureRandom.hex(4)}", email: "noacc@example.com", role: :player)
    assert_equal 0, new_player_no_accuracy.calculate_accuracy
  end

  test "#answered? returns true if user answered the question, false otherwise" do
    setup_for_instance_methods
    UserAnswer.create!(user: @player_for_methods, question: @q1_methods, answer: @ans_q1_correct)
    @player_for_methods.reload

    assert @player_for_methods.answered?(@q1_methods), "answered? should be true for @q1_methods"
    assert_not @player_for_methods.answered?(@q2_methods), "answered? should be false for @q2_methods"
  end

  test "#answer_for returns the UserAnswer record or nil" do
    setup_for_instance_methods
    ua = UserAnswer.create!(user: @player_for_methods, question: @q1_methods, answer: @ans_q1_correct)
    @player_for_methods.reload

    assert_equal ua, @player_for_methods.answer_for(@q1_methods)
    assert_nil @player_for_methods.answer_for(@q2_methods)
  end

  test "#unanswered_questions returns questions not yet answered by the user" do
    setup_for_instance_methods # This creates @q1_methods, @q2_methods, @q3_methods
    # @player_for_methods answers @q1_methods
    UserAnswer.create!(user: @player_for_methods, question: @q1_methods, answer: @ans_q1_correct)
    @player_for_methods.reload

    unanswered = @player_for_methods.unanswered_questions
    assert_includes unanswered, @q2_methods, "@q2_methods should be in unanswered list"
    assert_includes unanswered, @q3_methods, "@q3_methods should be in unanswered list"
    assert_not_includes unanswered, @q1_methods, "@q1_methods should NOT be in unanswered list"

    # Ensure the scope is specific to the user
    other_player = User.create!(facebook_id: "fb_other_unanswered_#{SecureRandom.hex(4)}", email: "other@example.com", role: :player)
    UserAnswer.create!(user: other_player, question: @q2_methods, answer: @ans_q2_correct) # Other user answers @q2_methods

    unanswered_for_main_player_again = @player_for_methods.unanswered_questions # Re-fetch
    assert_includes unanswered_for_main_player_again, @q2_methods # Still unanswered by @player_for_methods
  end

  test "#unanswered_questions returns all questions if user answered none" do
    new_player_all_unanswered = User.create!(facebook_id: "fb_unans_all_#{SecureRandom.hex(4)}", email: "unans@example.com", role: :player)
    # Count questions created by setup_for_instance_methods + any global fixtures
    # This can be tricky if Question.count is not stable.
    # Let's assume Question.count is the total number of questions available.
    expected_total_questions = Question.count
    assert_equal expected_total_questions, new_player_all_unanswered.unanswered_questions.count
  end

  test "#questions_by_category returns answered question counts grouped by category name" do
    player_qbc = User.create!(facebook_id: "fb_q_by_cat_test_#{SecureRandom.hex(4)}", email: "qbc@example.com", role: :player)

    cat_a = Category.find_or_create_by!(name: "QBC Category A")
    cat_b = Category.find_or_create_by!(name: "QBC Category B")
    cat_c_no_answers = Category.find_or_create_by!(name: "QBC Category C No Answers")


    cc_a1 = ClinicalCase.find_or_create_by!(name: "QBC CC A1", category: cat_a, description: "d")
    cc_a2 = ClinicalCase.find_or_create_by!(name: "QBC CC A2", category: cat_a, description: "d")
    cc_b1 = ClinicalCase.find_or_create_by!(name: "QBC CC B1", category: cat_b, description: "d")

    q_a1_1 = Question.find_or_create_by!(text: "QBC Q A1.1", clinical_case: cc_a1)
    q_a2_1 = Question.find_or_create_by!(text: "QBC Q A2.1", clinical_case: cc_a2) # Another question in Cat A
    q_b1_1 = Question.find_or_create_by!(text: "QBC Q B1.1", clinical_case: cc_b1)

    ans_q_a1_1 = Answer.find_or_create_by!(question: q_a1_1, text: "Ans", is_correct: true)
    ans_q_a2_1 = Answer.find_or_create_by!(question: q_a2_1, text: "Ans", is_correct: true)
    ans_q_b1_1 = Answer.find_or_create_by!(question: q_b1_1, text: "Ans", is_correct: true)

    UserAnswer.create!(user: player_qbc, question: q_a1_1, answer: ans_q_a1_1) # Cat A
    UserAnswer.create!(user: player_qbc, question: q_a2_1, answer: ans_q_a2_1) # Cat A (2nd q in Cat A)
    UserAnswer.create!(user: player_qbc, question: q_b1_1, answer: ans_q_b1_1) # Cat B
    player_qbc.reload

    counts = player_qbc.questions_by_category
    assert_kind_of Hash, counts
    assert_equal 2, counts[cat_a.name], "Count for #{cat_a.name} is wrong"
    assert_equal 1, counts[cat_b.name], "Count for #{cat_b.name} is wrong"
    assert_nil counts[cat_c_no_answers.name], "Category with no answered questions should not be in the hash"
  end

  test "#questions_by_category returns an empty hash if user answered no questions" do
    new_player_no_qbc = User.create!(facebook_id: "fb_qbc_no_ans_#{SecureRandom.hex(4)}", email: "noqbc@example.com", role: :player)
    assert_empty new_player_no_qbc.questions_by_category
  end

  # General validity test
  test "user with role player should be valid with email and optional facebook_id/name" do
    player = User.new(facebook_id: "fb_general_validity_#{SecureRandom.hex(4)}", email: "validity@example.com", role: :player)
    assert player.valid?, "User with facebook_id and email should be valid. Errors: #{player.errors.full_messages.join(", ")}"

    player.name = "New Player For Validity"
    assert player.valid?, "User with all optional fields should also be valid. Errors: #{player.errors.full_messages.join(", ")}"
  end
end

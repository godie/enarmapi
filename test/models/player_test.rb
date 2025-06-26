require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:player_answers)
    should have_many(:practiced_questions).through(:player_answers).source(:question)
    should have_many(:answers).through(:player_answers) # This implies answers chosen by the player
    should have_many(:player_exams)
    should have_many(:taken_exams).through(:player_exams).source(:exam)
  end

  context "validations" do
    setup do
      # players(:player_one) is from fixtures, ensure it's created for uniqueness check by shoulda
      Player.find_or_create_by!(facebook_id: players(:player_one).facebook_id) do |p|
        p.name = players(:player_one).name
        p.email = players(:player_one).email
      end
    end

    # Need a subject for shoulda-matchers uniqueness validation
    subject { Player.new(facebook_id: "fb_subject_player_unique_id") }
    should validate_presence_of(:facebook_id)
    should validate_uniqueness_of(:facebook_id)


    should allow_value("player@example.com").for(:email)
    should allow_value("player.name@example.co.uk").for(:email)
    should_not allow_value("player@example").for(:email) # Default message is "is invalid"
    should_not allow_value("player.com").for(:email)
    should allow_value(nil).for(:email) # email is allow_blank: true
    should allow_value("").for(:email)  # email is allow_blank: true

    should "be valid without a name (schema allows nil)" do
      player = Player.new(facebook_id: "fb_valid_id_for_nil_name_test_#{SecureRandom.hex(4)}")
      assert player.valid?, player.errors.full_messages.join(", ")
      assert player.save
      assert_nil player.reload.name
    end
  end

  setup do
    @player = players(:player_one)
    @category_one = categories(:one)
    @clinical_case_one = clinical_cases(:one) # Belongs to @category_one

    # Ensure questions are properly associated with clinical cases and categories for tests
    @question1 = Question.find_or_create_by!(text: "Q1 for PlayerTest", clinical_case: @clinical_case_one)
    @question2 = Question.find_or_create_by!(text: "Q2 for PlayerTest", clinical_case: @clinical_case_one)


    @answer_q1_correct = Answer.find_or_create_by!(question: @question1, text: "A1Q1 Correct", is_correct: true)
    @answer_q1_incorrect = Answer.find_or_create_by!(question: @question1, text: "A1Q1 Incorrect", is_correct: false)
    @answer_q2_correct = Answer.find_or_create_by!(question: @question2, text: "A1Q2 Correct", is_correct: true)

    # Clean up player answers before each test method in this main setup if needed, or per context.
    # For now, assuming tests will manage their own PlayerAnswer creations.
    # PlayerAnswer.where(player: @player).destroy_all
  end

  test "should be valid with facebook_id and optional email/name" do
    player = Player.new(facebook_id: "fb_new_unique_id_#{SecureRandom.hex(4)}")
    assert player.valid?, player.errors.full_messages.join(", ")
    player.email = "newplayer@example.com"
    player.name = "New Player Name"
    assert player.valid?
  end

  context "instance methods" do
    context "#stats" do
      setup do
        @player_for_stats = Player.create!(facebook_id: "fb_stats_test_#{SecureRandom.hex(4)}")
        @q_stats_1 = Question.create!(text: "Q Stats 1", clinical_case: @clinical_case_one)
        @ans_stats_1_correct = Answer.create!(question: @q_stats_1, text: "Ans Stats 1 Correct", is_correct: true)
        @q_stats_2 = Question.create!(text: "Q Stats 2", clinical_case: @clinical_case_one)
        @ans_stats_2_incorrect = Answer.create!(question: @q_stats_2, text: "Ans Stats 2 Incorrect", is_correct: false)
        @q_stats_3 = Question.create!(text: "Q Stats 3", clinical_case: @clinical_case_one)
        @ans_stats_3_correct = Answer.create!(question: @q_stats_3, text: "Ans Stats 3 Correct", is_correct: true)


        PlayerAnswer.create!(player: @player_for_stats, question: @q_stats_1, answer: @ans_stats_1_correct, time_taken: 10)
        PlayerAnswer.create!(player: @player_for_stats, question: @q_stats_2, answer: @ans_stats_2_incorrect, time_taken: 20)
        PlayerAnswer.create!(player: @player_for_stats, question: @q_stats_3, answer: @ans_stats_3_correct, time_taken: 15) # Another correct
        @player_for_stats.reload
      end

      should "return a hash with correct player statistics" do
        stats = @player_for_stats.stats
        assert_kind_of Hash, stats
        assert_equal 3, stats[:total_answers], "Total answers count mismatch"
        assert_equal 2, stats[:correct_answers], "Correct answers count mismatch"
        assert_equal 1, stats[:incorrect_answers], "Incorrect answers count mismatch"
        assert_equal ((2.0/3.0) * 100).round(2), stats[:accuracy_percentage], "Accuracy percentage mismatch"
        assert_equal 3, stats[:questions_answered], "Distinct questions answered count mismatch" # 3 distinct questions
        assert_not_nil stats[:last_activity], "Last activity should be present"
      end

      should "return zero/nil stats for a player with no answers" do
        new_player_no_answers = Player.create!(facebook_id: "fb_stats_no_answers_#{SecureRandom.hex(4)}")
        stats = new_player_no_answers.stats
        assert_equal 0, stats[:total_answers]
        assert_equal 0, stats[:correct_answers]
        assert_equal 0, stats[:incorrect_answers]
        assert_equal 0, stats[:accuracy_percentage]
        assert_equal 0, stats[:questions_answered]
        assert_nil stats[:last_activity]
      end
    end

    context "#calculate_accuracy" do
      setup do
        @player_for_accuracy = Player.create!(facebook_id: "fb_accuracy_#{SecureRandom.hex(4)}")
      end
      should "return correct accuracy percentage" do
        PlayerAnswer.create!(player: @player_for_accuracy, question: @question1, answer: @answer_q1_correct) # Correct
        PlayerAnswer.create!(player: @player_for_accuracy, question: @question2, answer: @answer_q1_incorrect) # Incorrect (answer is for Q1 but PA is for Q2, so is_correct depends on @answer_q1_incorrect.is_correct)
                                                                                                      # Let's make it clearly incorrect for Q2
        ans_q2_incorrect = Answer.create!(question: @question2, text: "Q2 Inc for Acc", is_correct: false)
        @player_for_accuracy.player_answers.where(question: @question2).destroy_all # remove previous one for Q2
        PlayerAnswer.create!(player: @player_for_accuracy, question: @question2, answer: ans_q2_incorrect) # Incorrect

        assert_equal 2, @player_for_accuracy.player_answers.count
        assert_equal 1, @player_for_accuracy.player_answers.correct.count
        assert_equal 50.0, @player_for_accuracy.calculate_accuracy
      end

      should "return 0 accuracy if no answers" do
        assert_equal 0, @player_for_accuracy.calculate_accuracy # No answers yet for this player
      end
    end

    context "#answered?" do
      setup do
        @player_for_answered_test = Player.create!(facebook_id: "fb_answered_#{SecureRandom.hex(4)}")
        PlayerAnswer.create!(player: @player_for_answered_test, question: @question1, answer: @answer_q1_correct)
      end
      should "return true if player has answered the question" do
        assert @player_for_answered_test.answered?(@question1)
      end

      should "return false if player has not answered the question" do
        assert_not @player_for_answered_test.answered?(@question2)
      end
    end

    context "#answer_for" do
       setup do
        @player_for_answer_for_test = Player.create!(facebook_id: "fb_answer_for_#{SecureRandom.hex(4)}")
        @pa = PlayerAnswer.create!(player: @player_for_answer_for_test, question: @question1, answer: @answer_q1_correct)
      end
      should "return the player's answer record for a given question" do
        assert_equal @pa, @player_for_answer_for_test.answer_for(@question1)
      end

      should "return nil if player has not answered the question" do
        assert_nil @player_for_answer_for_test.answer_for(@question2)
      end
    end

    context "#unanswered_questions" do
      setup do
        @player_for_unanswered = Player.create!(facebook_id: "fb_unanswered_#{SecureRandom.hex(4)}")
        # Question.count needs to be stable or known for this test.
        # Create some questions if not enough exist from fixtures.
        @q_un1 = @question1
        @q_un2 = @question2
        @q_un3 = Question.find_or_create_by!(text: "Unanswered Q for PlayerTest", clinical_case: @clinical_case_one)

        PlayerAnswer.create!(player: @player_for_unanswered, question: @q_un1, answer: @answer_q1_correct)
        @player_for_unanswered.reload
      end

      should "return questions not yet answered by the player" do
        unanswered = @player_for_unanswered.unanswered_questions
        assert_includes unanswered, @q_un2
        assert_includes unanswered, @q_un3
        assert_not_includes unanswered, @q_un1
        # Ensure it does not include questions answered by OTHER players but not this one
        other_player = Player.create!(facebook_id: "fb_other_for_unanswered_#{SecureRandom.hex(4)}")
        PlayerAnswer.create!(player: other_player, question: @q_un2, answer: @answer_q2_correct) # Other player answers q_un2

        unanswered_for_main_player = @player_for_unanswered.unanswered_questions # Re-fetch for @player_for_unanswered
        assert_includes unanswered_for_main_player, @q_un2 # @player_for_unanswered still hasn't answered q_un2
      end

      should "return all questions if player has answered none" do
        new_player_all_unanswered = Player.create!(facebook_id: "fb_all_unanswered_#{SecureRandom.hex(4)}")
        # This can be flaky if other tests add questions. Count before and after.
        expected_question_count = Question.count
        assert_equal expected_question_count, new_player_all_unanswered.unanswered_questions.count
      end
    end

    context "#questions_by_category" do
      setup do
        @player_for_q_by_cat = Player.create!(facebook_id: "fb_q_by_cat_#{SecureRandom.hex(4)}")

        @cat1_for_test = categories(:one) # e.g., Cardiología
        @cat2_for_test = categories(:two) # e.g., Neurología
        @cat3_for_test = Category.find_or_create_by!(name: "Test Category For PlayerTest")


        @cc_cat1 = ClinicalCase.find_or_create_by!(name: "CC Cat1 PlayerTest", category: @cat1_for_test, description: "Desc")
        @cc_cat2 = ClinicalCase.find_or_create_by!(name: "CC Cat2 PlayerTest", category: @cat2_for_test, description: "Desc")

        @q_c1_1 = Question.find_or_create_by!(text: "Q C1.1 PlayerTest", clinical_case: @cc_cat1)
        @q_c1_2 = Question.find_or_create_by!(text: "Q C1.2 PlayerTest", clinical_case: @cc_cat1)
        @q_c2_1 = Question.find_or_create_by!(text: "Q C2.1 PlayerTest", clinical_case: @cc_cat2)

        @ans_q_c1_1 = Answer.find_or_create_by!(question: @q_c1_1, text: "Ans C1.1", is_correct: true)
        @ans_q_c1_2 = Answer.find_or_create_by!(question: @q_c1_2, text: "Ans C1.2", is_correct: true)
        @ans_q_c2_1 = Answer.find_or_create_by!(question: @q_c2_1, text: "Ans C2.1", is_correct: true)

        PlayerAnswer.create!(player: @player_for_q_by_cat, question: @q_c1_1, answer: @ans_q_c1_1)
        PlayerAnswer.create!(player: @player_for_q_by_cat, question: @q_c1_2, answer: @ans_q_c1_2) # Two for @cat1_for_test
        PlayerAnswer.create!(player: @player_for_q_by_cat, question: @q_c2_1, answer: @ans_q_c2_1) # One for @cat2_for_test
        @player_for_q_by_cat.reload
      end

      should "return a hash of answered question counts grouped by category name" do
        counts = @player_for_q_by_cat.questions_by_category
        assert_kind_of Hash, counts
        assert_equal 2, counts[@cat1_for_test.name], "Count for #{@cat1_for_test.name} is wrong"
        assert_equal 1, counts[@cat2_for_test.name], "Count for #{@cat2_for_test.name} is wrong"
        assert_nil counts[@cat3_for_test.name], "Should not include categories with no answered questions"
      end

      should "return an empty hash if player has answered no questions" do
        new_player_no_q_by_cat = Player.create!(facebook_id: "fb_no_q_by_cat_#{SecureRandom.hex(4)}")
        assert_empty new_player_no_q_by_cat.questions_by_category
      end
    end
  end
end

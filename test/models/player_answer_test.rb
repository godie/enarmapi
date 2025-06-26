require "test_helper"

class PlayerAnswerTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:player)
    should belong_to(:question)
    should belong_to(:answer)
  end

  context "validations" do
    setup do
      # Create a PlayerAnswer to test uniqueness against
      @player = players(:player_one)
      @question = questions(:one)
      @answer = answers(:one) # Assuming this answer belongs to @question
      @answer.update!(question: @question) if @answer.question != @question

      PlayerAnswer.create!(player: @player, question: @question, answer: @answer)
    end

    # For shoulda-matchers, subject needs to be a new, unsaved record.
    # The existing record for uniqueness check is created in the setup block.
    subject do
      PlayerAnswer.new(
        player: @player, # Same player
        question: questions(:two), # Different question initially for subject to be valid itself
        answer: answers(:three) # An answer corresponding to questions(:two)
      )
    end
    should validate_uniqueness_of(:player_id).scoped_to(:question_id).with_message("ya ha respondido esta pregunta")

    should validate_presence_of(:question_id) # This is implicitly handled by `belongs_to :question`
    should validate_presence_of(:answer_id)   # This is implicitly handled by `belongs_to :answer`

    # Explicit tests for presence of associations
    should "be invalid without a player" do
      pa = PlayerAnswer.new(question: @question, answer: @answer)
      assert_not pa.valid?
      assert_includes pa.errors[:player], "must exist"
    end

    should "be invalid without a question" do
      pa = PlayerAnswer.new(player: @player, answer: @answer)
      assert_not pa.valid?
      assert_includes pa.errors[:question], "must exist" # Error is on :question, not :question_id
    end

    should "be invalid without an answer" do
      pa = PlayerAnswer.new(player: @player, question: @question)
      assert_not pa.valid?
      assert_includes pa.errors[:answer], "must exist" # Error is on :answer, not :answer_id
    end

    test "uniqueness of player_id scoped to question_id (manual test)" do
      # First PlayerAnswer created in setup for @player and @question
      another_answer_for_same_question = Answer.create!(question: @question, text: "Another ans for Q1", is_correct: false)
      duplicate_pa = PlayerAnswer.new(
        player: @player,
        question: @question, # Same player, same question
        answer: another_answer_for_same_question # Different answer, but still a duplicate PA for (player, question)
      )
      assert_not duplicate_pa.valid?
      assert_includes duplicate_pa.errors[:player_id], "ya ha respondido esta pregunta"
    end
  end

  context "callbacks" do
    context "before_create :set_correctness" do
      setup do
        @player_cb = players(:player_two) # Use a different player to avoid uniqueness conflicts
        @question_cb = questions(:two)
      end

      should "set is_correct to true if the chosen answer is correct" do
        correct_answer = Answer.create!(question: @question_cb, text: "Correct CB Ans", is_correct: true)
        pa = PlayerAnswer.create!(player: @player_cb, question: @question_cb, answer: correct_answer)
        assert_equal true, pa.is_correct
      end

      should "set is_correct to false if the chosen answer is incorrect" do
        incorrect_answer = Answer.create!(question: @question_cb, text: "Incorrect CB Ans", is_correct: false)
        pa = PlayerAnswer.create!(player: @player_cb, question: @question_cb, answer: incorrect_answer)
        assert_equal false, pa.is_correct
      end

      should "set is_correct to nil if the chosen answer's is_correct is nil" do
        # This case might be unlikely if Answer.is_correct is boolean NOT NULL,
        # but the schema allows boolean to be nil if not specified otherwise.
        # Our schema for Answer: t.boolean "is_correct" (does not say default or not null)
        nil_correct_answer = Answer.create!(question: @question_cb, text: "Nil Correct CB Ans", is_correct: nil)
        pa = PlayerAnswer.create!(player: @player_cb, question: @question_cb, answer: nil_correct_answer)
        assert_nil pa.is_correct
      end

      should "not set is_correct if answer is somehow not present (though validation should prevent this)" do
        # This tests robustness of the callback, though :answer presence is validated.
        pa = PlayerAnswer.new(player: @player_cb, question: @question_cb, answer: nil)
        pa.valid? # Trigger validations
        # Manually call callback if `create` is bypassed or to test in isolation (not typical for `create`)
        # For `create!`, if answer is nil, it would fail validation before callback.
        # If we build and then save:
        pa.send(:set_correctness) # Call directly for test purposes
        assert_nil pa.is_correct # Should remain as default (nil)
      end
    end
    # `after_create :update_player_stats` is commented out in the model.
  end

  context "scopes" do
    setup do
      # Clean slate for scope tests for a specific player/question set
      PlayerAnswer.delete_all # Be careful with this in larger test suites

      @player_scope = Player.create!(facebook_id: "fb_scope_test_player")
      @question_scope1 = Question.create!(text: "Scope Q1", clinical_case: clinical_cases(:one))
      @question_scope2 = Question.create!(text: "Scope Q2", clinical_case: clinical_cases(:one))

      @ans_q_scope1_correct = Answer.create!(question: @question_scope1, text: "Ans Scope Q1 Correct", is_correct: true)
      @ans_q_scope1_incorrect = Answer.create!(question: @question_scope1, text: "Ans Scope Q1 Incorrect", is_correct: false)
      @ans_q_scope2_correct = Answer.create!(question: @question_scope2, text: "Ans Scope Q2 Correct", is_correct: true)

      # Create player answers with varying correctness and timestamps
      @pa_correct_recent = PlayerAnswer.create!(player: @player_scope, question: @question_scope1, answer: @ans_q_scope1_correct, created_at: Time.now)
      # To make pa_incorrect_old distinct from pa_correct_recent for (player, question) uniqueness, use a different question or player.
      # The current validation is (player_id, question_id).
      # So, for the same player, we need a different question for the second PlayerAnswer.
      # Let's use @question_scope2 for the second PA.
      @pa_incorrect_old = PlayerAnswer.create!(player: @player_scope, question: @question_scope2, answer: @ans_q_scope2_correct, created_at: 1.day.ago)
      # The above is also correct. Let's make one that is incorrect.
      # Need a third question for the same player if we want another PA.
      @question_scope3 = Question.create!(text: "Scope Q3 for incorrect", clinical_case: clinical_cases(:one))
      @ans_q_scope3_incorrect = Answer.create!(question: @question_scope3, text: "Ans Scope Q3 Incorrect", is_correct: false)
      @pa_truly_incorrect_recent = PlayerAnswer.create!(player: @player_scope, question: @question_scope3, answer: @ans_q_scope3_incorrect, created_at: 30.minutes.ago)


      # Update @pa_incorrect_old to be actually incorrect for the test name.
      # This requires changing its answer or the answer's correctness.
      # Let's change the answer to an incorrect one for @question_scope2
      incorrect_answer_for_q_scope2 = Answer.create!(question: @question_scope2, text: "Incorrect for Q Scope 2", is_correct: false)
      @pa_incorrect_old.update!(answer: incorrect_answer_for_q_scope2) # This will re-trigger set_correctness if using after_save, but it's before_create.
      # Manually set is_correct for testing scopes if callback doesn't re-run on update.
      @pa_incorrect_old.update_column(:is_correct, false)


    end

    should "return only correct answers for :correct scope" do
      correct_answers = PlayerAnswer.correct
      assert_includes correct_answers, @pa_correct_recent
      assert_not_includes correct_answers, @pa_incorrect_old
      assert_not_includes correct_answers, @pa_truly_incorrect_recent
      assert_equal 1, correct_answers.count # Only @pa_correct_recent is correct now
    end

    should "return only incorrect answers for :incorrect scope" do
      incorrect_answers = PlayerAnswer.incorrect
      assert_includes incorrect_answers, @pa_incorrect_old
      assert_includes incorrect_answers, @pa_truly_incorrect_recent
      assert_not_includes incorrect_answers, @pa_correct_recent
      assert_equal 2, incorrect_answers.count
    end

    should "order answers by creation date descending for :recent scope" do
      # @pa_correct_recent (Time.now)
      # @pa_truly_incorrect_recent (30.minutes.ago)
      # @pa_incorrect_old (1.day.ago)

      # Get all PAs for this player to check order
      all_player_answers_for_scope_test = PlayerAnswer.where(player: @player_scope)
      # Ensure we have the right number of items before checking order
      assert_equal 3, all_player_answers_for_scope_test.count

      recent_answers = PlayerAnswer.where(player: @player_scope).recent.to_a

      expected_order = [@pa_correct_recent, @pa_truly_incorrect_recent, @pa_incorrect_old]
      assert_equal expected_order.map(&:id), recent_answers.map(&:id)
    end

    should "filter answers by question_id for :by_question scope" do
      answers_for_q1 = PlayerAnswer.by_question(@question_scope1.id)
      assert_includes answers_for_q1, @pa_correct_recent
      assert_equal 1, answers_for_q1.count

      answers_for_q2 = PlayerAnswer.by_question(@question_scope2.id)
      assert_includes answers_for_q2, @pa_incorrect_old
      assert_equal 1, answers_for_q2.count

      answers_for_q3 = PlayerAnswer.by_question(@question_scope3.id)
      assert_includes answers_for_q3, @pa_truly_incorrect_recent
      assert_equal 1, answers_for_q3.count
    end
  end

  test "should be valid with all required associations and attributes" do
    player = players(:player_one)
    # Use a new question to avoid uniqueness collision from setup
    question = Question.create!(text: "PA Valid Test Q", clinical_case: clinical_cases(:one))
    answer = Answer.create!(question: question, text: "PA Valid Test A", is_correct: true)

    pa = PlayerAnswer.new(
      player: player,
      question: question,
      answer: answer,
      time_taken: 100,
      mode: "practice" # default is 'practice'
    )
    assert pa.valid?, pa.errors.full_messages.join(", ")
  end

  test "time_taken can be nil" do
    # Schema: t.integer "time_taken" (nullable)
    pa = PlayerAnswer.new(player: players(:one), question: questions(:two), answer: answers(:three), time_taken: nil)
    # Need to ensure questions(:two) and answers(:three) are compatible and player hasn't answered questions(:two)
    # Let's use fresh objects to be safe
    p = Player.create!(facebook_id: "fb_pa_nil_time_#{SecureRandom.hex(3)}")
    q = Question.create!(text: "Q for nil time", clinical_case: clinical_cases(:one))
    a = Answer.create!(question: q, text: "A for nil time", is_correct: true)

    pa_with_nil_time = PlayerAnswer.new(player: p, question: q, answer: a, time_taken: nil)
    assert pa_with_nil_time.valid?, pa_with_nil_time.errors.full_messages.join(", ")
    assert pa_with_nil_time.save
    assert_nil pa_with_nil_time.reload.time_taken
  end

  test "mode defaults to 'practice'" do
    # Schema: t.string "mode", default: "practice"
    p = Player.create!(facebook_id: "fb_pa_mode_default_#{SecureRandom.hex(3)}")
    q = Question.create!(text: "Q for mode default", clinical_case: clinical_cases(:one))
    a = Answer.create!(question: q, text: "A for mode default", is_correct: true)

    pa = PlayerAnswer.new(player: p, question: q, answer: a)
    assert pa.save # Save to allow default to be applied if it's DB level or AR default
    assert_equal "practice", pa.reload.mode
  end

  test "mode can be set to other values" do
    p = Player.create!(facebook_id: "fb_pa_mode_set_#{SecureRandom.hex(3)}")
    q = Question.create!(text: "Q for mode set", clinical_case: clinical_cases(:one))
    a = Answer.create!(question: q, text: "A for mode set", is_correct: true)

    pa = PlayerAnswer.new(player: p, question: q, answer: a, mode: "test_mode")
    assert pa.save
    assert_equal "test_mode", pa.reload.mode
  end
end

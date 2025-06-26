require 'test_helper'

module Achievements
  class UnlockServiceTest < ActiveSupport::TestCase
    # Load all fixtures for simplicity in service tests, or specify as needed
    fixtures :players, :achievements, :categories, :player_achievements,
             :exams, :player_exams, :questions, :answers, :clinical_cases # Add other relevant fixtures

    def setup
      # Using fixtures for player and achievements
      @player = players(:player_for_achievements) # A dedicated player for these tests

      # Clean up any existing achievements, player_exams, and player_answers for this player
      # to ensure a clean state for each test concerning this specific player.
      PlayerAchievement.where(player: @player).destroy_all
      PlayerExam.where(player: @player).destroy_all
      PlayerAnswer.where(player: @player).destroy_all # Assuming PlayerAnswer has player_id

      # Achievements from fixtures
      @ach_exams_1 = achievements(:exams_completed_1) # Criteria: { type: "exams_completed", count: 1 }
      @ach_exams_5 = achievements(:exams_completed_5) # Criteria: { type: "exams_completed", count: 5 }
      @ach_urgencias_expert = achievements(:category_urgencias_expert) # Criteria linked to urgencias category

      @urgencias_category = categories(:urgencias) # Category from fixtures

      # Ensure criteria for urgencias expert is correctly linked if dynamic fixture loading didn't catch it
      # This is more of a safeguard if ActiveRecord::FixtureSet.identify didn't work as expected in yml
      if @ach_urgencias_expert.criteria["category_id"].blank? && @urgencias_category
         @ach_urgencias_expert.update!(criteria: @ach_urgencias_expert.criteria.merge(category_id: @urgencias_category.id))
         @ach_urgencias_expert.reload
      end

      # Clean up any existing achievements for this player to ensure clean test state
      PlayerAchievement.where(player: @player).destroy_all
    end

    test "unlocks 'Pionero del Saber' (1 exam completed) achievement" do
      # Simulate player completing 1 exam
      # This requires creating related data like Exam, PlayerExam
      exam = Exam.create!(name: "Test Exam 1", category: @urgencias_category) # Assuming Exam model needs a category
      PlayerExam.create!(player: @player, exam: exam, score: 80, completed_at: Time.current) # Assuming PlayerExam needs score & completed_at

      assert_difference "PlayerAchievement.count", 1 do
        unlocked = Achievements::UnlockService.new(@player).call
        assert_includes unlocked, @ach_exams_1, "Should unlock 'Pionero del Saber'"
      end

      assert @player.achievements.exists?(@ach_exams_1.id), "'Pionero del Saber' should be associated with the player"
    end

    test "unlocks 'Estudiante Dedicado' (5 exams completed) achievement" do
      # Simulate player completing 5 exams
      exam_category = @urgencias_category || Category.first || Category.create!(name: "General Test Category")
      5.times do |i|
        exam = Exam.create!(name: "Test Exam #{i+1}", category: exam_category)
        PlayerExam.create!(player: @player, exam: exam, score: 70 + i*5, completed_at: Time.current)
      end

      # It should unlock both 1 exam and 5 exams achievements if player had none
      # Expecting 2 achievements if the player starts with 0 exams completed.
      # If "Pionero del Saber" was already unlocked in a previous test/state for this player, adjust count.
      # For isolated test, we expect 2 (1 exam, 5 exams)

      # Ensure the player has no achievements before this specific test part
      PlayerAchievement.where(player: @player).destroy_all

      expected_unlocks = [@ach_exams_1, @ach_exams_5]

      assert_difference "PlayerAchievement.count", expected_unlocks.size do
        unlocked = Achievements::UnlockService.new(@player).call
        expected_unlocks.each do |ach|
          assert_includes unlocked, ach, "Should unlock '#{ach.name}'"
        end
      end

      expected_unlocks.each do |ach|
        assert @player.achievements.exists?(ach.id), "'#{ach.name}' should be associated"
      end
    end

    test "does not unlock achievement if player already has it" do
      # Give player the achievement first
      PlayerAchievement.create!(player: @player, achievement: @ach_exams_1)

      # Simulate completing 1 exam again
      exam = Exam.create!(name: "Test Exam Repeat", category: @urgencias_category)
      PlayerExam.create!(player: @player, exam: exam, score: 80, completed_at: Time.current)

      assert_no_difference "PlayerAchievement.count" do
        unlocked = Achievements::UnlockService.new(@player).call
        assert_empty unlocked, "Should not unlock any new achievements"
      end
    end

    test "unlocks 'Maestro de Urgencias' (category accuracy) achievement" do
      # Ensure the achievement criteria has the correct category_id
      unless @ach_urgencias_expert.criteria["category_id"] == @urgencias_category.id
        @ach_urgencias_expert.update!(criteria: @ach_urgencias_expert.criteria.merge("category_id" => @urgencias_category.id))
        @ach_urgencias_expert.reload
      end

      min_exams_needed = @ach_urgencias_expert.criteria["min_exams_in_category"].to_i # e.g. 2
      accuracy_threshold = @ach_urgencias_expert.criteria["accuracy_threshold"].to_f # e.g. 80

      # Simulate player taking exams in 'Urgencias' with high accuracy
      # Create questions and answers for these exams
      questions_per_exam = 5

      min_exams_needed.times do |i|
        exam = Exam.create!(name: "Urgencias Exam #{i+1}", category: @urgencias_category)
        PlayerExam.create!(player: @player, exam: exam, score: accuracy_threshold.to_i + 5, completed_at: Time.current) # High score

        questions_per_exam.times do |j|
          question = Question.create!(
            clinical_case: ClinicalCase.create!(name: "Case U-#{i}-#{j}", category: @urgencias_category, description: "Desc U-#{i}-#{j}"),
            text: "Question U-#{i}-#{j}?"
          )
          # Player answers 4 out of 5 correctly to get 80%
          # Or all correctly for >80%
          PlayerAnswer.create!(
            player: @player,
            question: question,
            answer: Answer.create!(question: question, text: "Correct", is_correct: true), # Assuming Answer model
            is_correct: true # Assuming PlayerAnswer stores this directly
            # exam: exam # Removed: PlayerAnswer does not directly belong to Exam
          )
        end
      end

      # Also check for "Pionero del Saber" and potentially others if counts match
      # For this test, we focus on "Maestro de Urgencias" specifically by ensuring other simpler ones are met
      # Or clear existing to only test this one. Let's clear for isolation.
      PlayerAchievement.where(player: @player).destroy_all

      # The service will also award "Pionero del Saber" and potentially "Estudiante Dedicado"
      # if min_exams_needed meets those counts.
      # Let's assume min_exams_needed is 2 for Maestro de Urgencias.
      # Then Pionero del Saber (1 exam) will also be awarded.

      expected_new_achievements_count = 1 # for Maestro de Urgencias
      if min_exams_needed >= @ach_exams_1.criteria["count"].to_i && !@player.achievements.exists?(@ach_exams_1.id)
         expected_new_achievements_count +=1
      end
      if min_exams_needed >= @ach_exams_5.criteria["count"].to_i && !@player.achievements.exists?(@ach_exams_5.id)
         expected_new_achievements_count +=1
      end


      assert_difference "PlayerAchievement.count", expected_new_achievements_count do
        unlocked = Achievements::UnlockService.new(@player).call
        assert_includes unlocked, @ach_urgencias_expert, "Should unlock 'Maestro de Urgencias'"
        if expected_new_achievements_count > 1 && min_exams_needed >= @ach_exams_1.criteria["count"].to_i
            assert_includes unlocked, @ach_exams_1, "Should also unlock 'Pionero del Saber'"
        end
      end

      assert @player.achievements.exists?(@ach_urgencias_expert.id), "'Maestro de Urgencias' should be associated"
    end

    test "does not unlock 'Maestro de Urgencias' if accuracy is too low" do
      min_exams_needed = @ach_urgencias_expert.criteria["min_exams_in_category"].to_i

      min_exams_needed.times do |i|
        exam = Exam.create!(name: "Low Score Urgencias Exam #{i+1}", category: @urgencias_category)
        PlayerExam.create!(player: @player, exam: exam, score: 50, completed_at: Time.current) # Low score

        question = Question.create!(
          clinical_case: ClinicalCase.create!(name: "Case U-Low-#{i}", category: @urgencias_category, description: "Desc U-Low-#{i}"),
          text: "Question U-Low-#{i}?"
        )
        PlayerAnswer.create!(
          player: @player,
          question: question,
          answer: Answer.create!(question: question, text: "Incorrect", is_correct: false),
          is_correct: false
          # exam: exam # Removed: PlayerAnswer does not directly belong to Exam
        )
      end

      # The service might still unlock "Pionero del Saber" or "Estudiante Dedicado"
      # We are checking that "Maestro de Urgencias" is NOT unlocked.
      unlocked = Achievements::UnlockService.new(@player).call
      assert_not_includes unlocked, @ach_urgencias_expert, "Should NOT unlock 'Maestro de Urgencias' with low accuracy"
      assert_not @player.achievements.exists?(@ach_urgencias_expert.id), "'Maestro de Urgencias' should NOT be associated"
    end

    test "does not unlock 'Maestro de Urgencias' if not enough exams in category" do
      # Only 1 exam in category, but min_exams_in_category is likely 2 or more
      if @ach_urgencias_expert.criteria["min_exams_in_category"].to_i > 1
        exam = Exam.create!(name: "Single High Score Urgencias Exam", category: @urgencias_category)
        PlayerExam.create!(player: @player, exam: exam, score: 90, completed_at: Time.current)

        question = Question.create!(
          clinical_case: ClinicalCase.create!(name: "Case U-Single-High", category: @urgencias_category, description: "Desc U-Single-High"),
          text: "Question U-Single-High?"
        )
        PlayerAnswer.create!(player: @player, question: question, answer: Answer.create!(question: question, text: "Correct", is_correct: true), is_correct: true) # Removed exam: exam

        unlocked = Achievements::UnlockService.new(@player).call
        assert_not_includes unlocked, @ach_urgencias_expert, "Should NOT unlock 'Maestro de Urgencias' with insufficient exams in category"
        assert_not @player.achievements.exists?(@ach_urgencias_expert.id), "'Maestro de Urgencias' should NOT be associated"
      else
        # Skip this test if min_exams_in_category is 1, as it wouldn't test the condition properly.
        pass "Skipping test: min_exams_in_category for 'Maestro de Urgencias' is not greater than 1."
      end
    end

  end
end

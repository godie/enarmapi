require "test_helper"

module Achievements
  class UnlockServiceTest < ActiveSupport::TestCase
    # Load all fixtures for simplicity in service tests, or specify as needed
    fixtures :users, :achievements, :categories, :user_achievements, # Changed from players, player_achievements
             :exams, :user_exams, :questions, :answers, :clinical_cases # Changed from player_exams

    def setup
      # Using fixtures for user and achievements
      @player = users(:player_for_achievements) # Changed from players(:player_for_achievements)

      # Clean up any existing achievements, user_exams, and user_answers for this user
      # to ensure a clean state for each test concerning this specific user.
      UserAchievement.where(user: @player).destroy_all # Changed from PlayerAchievement, player
      UserExam.where(user: @player).destroy_all # Changed from PlayerExam, player
      UserAnswer.where(user: @player).destroy_all # Changed from PlayerAnswer, player

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

      # Clean up any existing achievements for this user to ensure clean test state
      UserAchievement.where(user: @player).destroy_all # Changed from PlayerAchievement, player
    end

    test "unlocks 'Pionero del Saber' (1 exam completed) achievement" do
      # Simulate user completing 1 exam
      # This requires creating related data like Exam, UserExam
      exam = Exam.create!(name: "Test Exam 1", category: @urgencias_category) # Assuming Exam model needs a category
      UserExam.create!(user: @player, exam: exam, score: 80, completed_at: Time.current) # Changed from PlayerExam, player

      assert_difference "UserAchievement.count", 1 do # Changed from PlayerAchievement.count
        unlocked = Achievements::UnlockService.new(@player).call
        assert_includes unlocked, @ach_exams_1, "Should unlock 'Pionero del Saber'"
      end

      assert @player.achievements.exists?(@ach_exams_1.id), "'Pionero del Saber' should be associated with the user"
    end

    test "unlocks 'Estudiante Dedicado' (5 exams completed) achievement" do
      # Simulate user completing 5 exams
      exam_category = @urgencias_category || Category.first || Category.create!(name: "General Test Category")
      5.times do |i|
        exam = Exam.create!(name: "Test Exam #{i+1}", category: exam_category)
        UserExam.create!(user: @player, exam: exam, score: 70 + i*5, completed_at: Time.current) # Changed from PlayerExam, player
      end

      # It should unlock both 1 exam and 5 exams achievements if user had none
      # Expecting 2 achievements if the user starts with 0 exams completed.
      # If "Pionero del Saber" was already unlocked in a previous test/state for this user, adjust count.
      # For isolated test, we expect 2 (1 exam, 5 exams)

      # Ensure the user has no achievements before this specific test part
      UserAchievement.where(user: @player).destroy_all # Changed from PlayerAchievement, player

      expected_unlocks = [ @ach_exams_1, @ach_exams_5 ]

      assert_difference "UserAchievement.count", expected_unlocks.size do # Changed from PlayerAchievement.count
        unlocked = Achievements::UnlockService.new(@player).call
        expected_unlocks.each do |ach|
          assert_includes unlocked, ach, "Should unlock '#{ach.name}'"
        end
      end

      expected_unlocks.each do |ach|
        assert @player.achievements.exists?(ach.id), "'#{ach.name}' should be associated"
      end
    end

    test "does not unlock achievement if user already has it" do
      # Give user the achievement first
      UserAchievement.create!(user: @player, achievement: @ach_exams_1) # Changed from PlayerAchievement, player

      # Simulate completing 1 exam again
      exam = Exam.create!(name: "Test Exam Repeat", category: @urgencias_category)
      UserExam.create!(user: @player, exam: exam, score: 80, completed_at: Time.current) # Changed from PlayerExam, player

      assert_no_difference "UserAchievement.count" do # Changed from PlayerAchievement.count
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

      # Simulate user taking exams in 'Urgencias' with high accuracy
      # Create questions and answers for these exams
      questions_per_exam = 5

      min_exams_needed.times do |i|
        exam = Exam.create!(name: "Urgencias Exam #{i+1}", category: @urgencias_category)
        UserExam.create!(user: @player, exam: exam, score: accuracy_threshold.to_i + 5, completed_at: Time.current) # Changed from PlayerExam, player

        questions_per_exam.times do |j|
          question = Question.create!(
            clinical_case: ClinicalCase.create!(name: "Case U-#{i}-#{j}", category: @urgencias_category, description: "Desc U-#{i}-#{j}"),
            text: "Question U-#{i}-#{j}?"
          )
          # User answers 4 out of 5 correctly to get 80%
          # Or all correctly for >80%
          UserAnswer.create!( # Changed from PlayerAnswer, player
            user: @player,
            question: question,
            answer: Answer.create!(question: question, text: "Correct", is_correct: true), # Assuming Answer model
            is_correct: true # Assuming UserAnswer stores this directly
          )
        end
      end

      # Also check for "Pionero del Saber" and potentially others if counts match
      # For this test, we focus on "Maestro de Urgencias" specifically by ensuring other simpler ones are met
      # Or clear existing to only test this one. Let's clear for isolation.
      UserAchievement.where(user: @player).destroy_all # Changed from PlayerAchievement, player

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


      assert_difference "UserAchievement.count", expected_new_achievements_count do # Changed from PlayerAchievement.count
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
        UserExam.create!(user: @player, exam: exam, score: 50, completed_at: Time.current) # Changed from PlayerExam, player

        question = Question.create!(
          clinical_case: ClinicalCase.create!(name: "Case U-Low-#{i}", category: @urgencias_category, description: "Desc U-Low-#{i}"),
          text: "Question U-Low-#{i}?"
        )
        UserAnswer.create!( # Changed from PlayerAnswer, player
          user: @player,
          question: question,
          answer: Answer.create!(question: question, text: "Incorrect", is_correct: false),
          is_correct: false
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
        UserExam.create!(user: @player, exam: exam, score: 90, completed_at: Time.current) # Changed from PlayerExam, player

        question = Question.create!(
          clinical_case: ClinicalCase.create!(name: "Case U-Single-High", category: @urgencias_category, description: "Desc U-Single-High"),
          text: "Question U-Single-High?"
        )
        UserAnswer.create!(user: @player, question: question, answer: Answer.create!(question: question, text: "Correct", is_correct: true), is_correct: true) # Changed from PlayerAnswer, player

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

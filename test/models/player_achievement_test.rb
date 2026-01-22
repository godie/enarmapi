require "test_helper"

class PlayerAchievementTest < ActiveSupport::TestCase
  fixtures :users, :achievements, :user_achievements

  def setup
    # Use a user and achievement combination that is NOT in user_achievements.yml for most creation tests
    @player_for_new_ach = users(:player_two)
    @achievement_for_new_ach = achievements(:exams_completed_5) # Assuming player two hasn't earned exams_completed_5 via fixtures

    # For tests that rely on an existing UserAchievement, use the one from fixtures
    @existing_user_achievement = user_achievements(:player_one_got_first_exam_achievement)
    @player_with_existing_ach = @existing_user_achievement.user # users(:player_one)
    @existing_achievement = @existing_user_achievement.achievement # achievements(:exams_completed_1)

    # Clean up any potential conflicting UserAchievement for the 'new' combination before each test
    UserAchievement.where(user: @player_for_new_ach, achievement: @achievement_for_new_ach).destroy_all
  end

  test "should be valid with a new user and an achievement" do
    user_achievement = UserAchievement.new(user: @player_for_new_ach, achievement: @achievement_for_new_ach)
    assert user_achievement.valid?, "UserAchievement should be valid. Errors: #{user_achievement.errors.full_messages.join(", ")}"
  end

  test "should require a user" do # Test with nil user
    user_achievement = UserAchievement.new(achievement: @achievement_for_new_ach)
    assert_not user_achievement.valid?
    assert_includes user_achievement.errors[:user], "must exist"
  end

  test "should require an achievement" do # Test with nil achievement
    user_achievement = UserAchievement.new(user: @player_for_new_ach)
    assert_not user_achievement.valid?
    assert_includes user_achievement.errors[:achievement], "must exist"
  end

  test "user_id should be unique per achievement_id (testing against existing fixture)" do
    # This relies on @existing_user_achievement (player_one + exams_completed_1)
    duplicate_user_achievement = UserAchievement.new(user: @player_with_existing_ach, achievement: @existing_achievement)
    assert_not duplicate_user_achievement.valid?
    assert_includes duplicate_user_achievement.errors[:user_id], "ya ha ganado este logro"
  end

  test "user_id should be unique per achievement_id (testing by creating one first)" do
    # Create a new one first
    assert_difference "UserAchievement.count" do
      UserAchievement.create!(user: @player_for_new_ach, achievement: @achievement_for_new_ach)
    end
    # Then try to duplicate it
    duplicate_user_achievement = UserAchievement.new(user: @player_for_new_ach, achievement: @achievement_for_new_ach)
    assert_not duplicate_user_achievement.valid?
    assert_includes duplicate_user_achievement.errors[:user_id], "ya ha ganado este logro"
  end


  test "achieved_at should be set on creation" do
    user_achievement = UserAchievement.new(user: @player_for_new_ach, achievement: @achievement_for_new_ach)
    assert_nil user_achievement.achieved_at
    assert user_achievement.save, "Should save successfully. Errors: #{user_achievement.errors.full_messages.join(", ")}"
    assert_not_nil user_achievement.achieved_at
    assert_in_delta Time.current, user_achievement.achieved_at, 1.second
  end

  test "progress can be stored as json" do
    progress_data = { current: 5, total: 10 }
    user_achievement = UserAchievement.new(
      user: @player_for_new_ach,
      achievement: @achievement_for_new_ach,
      progress: progress_data
    )
    assert user_achievement.save, "Should save successfully. Errors: #{user_achievement.errors.full_messages.join(", ")}"
    assert_equal progress_data.with_indifferent_access, user_achievement.reload.progress
  end
end

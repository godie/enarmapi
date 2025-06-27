require "test_helper"

class PlayerAchievementTest < ActiveSupport::TestCase
  fixtures :players, :achievements, :player_achievements

  def setup
    # Use a player and achievement combination that is NOT in player_achievements.yml for most creation tests
    @player_for_new_ach = players(:player_two)
    @achievement_for_new_ach = achievements(:exams_completed_5) # Assuming player two hasn't earned exams_completed_5 via fixtures

    # For tests that rely on an existing PlayerAchievement, use the one from fixtures
    @existing_player_achievement = player_achievements(:player_one_got_first_exam_achievement)
    @player_with_existing_ach = @existing_player_achievement.player # players(:one)
    @existing_achievement = @existing_player_achievement.achievement # achievements(:exams_completed_1)

    # Clean up any potential conflicting PlayerAchievement for the 'new' combination before each test
    PlayerAchievement.where(player: @player_for_new_ach, achievement: @achievement_for_new_ach).destroy_all
  end

  test "should be valid with a new player and an achievement" do
    player_achievement = PlayerAchievement.new(player: @player_for_new_ach, achievement: @achievement_for_new_ach)
    assert player_achievement.valid?, "PlayerAchievement should be valid. Errors: #{player_achievement.errors.full_messages.join(", ")}"
  end

  test "should require a player" do # Test with nil player
    player_achievement = PlayerAchievement.new(achievement: @achievement_for_new_ach)
    assert_not player_achievement.valid?
    assert_includes player_achievement.errors[:player], "must exist"
  end

  test "should require an achievement" do # Test with nil achievement
    player_achievement = PlayerAchievement.new(player: @player_for_new_ach)
    assert_not player_achievement.valid?
    assert_includes player_achievement.errors[:achievement], "must exist"
  end

  test "player_id should be unique per achievement_id (testing against existing fixture)" do
    # This relies on @existing_player_achievement (player_one + exams_completed_1)
    duplicate_player_achievement = PlayerAchievement.new(player: @player_with_existing_ach, achievement: @existing_achievement)
    assert_not duplicate_player_achievement.valid?
    assert_includes duplicate_player_achievement.errors[:player_id], "has already earned this achievement"
  end

  test "player_id should be unique per achievement_id (testing by creating one first)" do
    # Create a new one first
    assert_difference "PlayerAchievement.count" do
      PlayerAchievement.create!(player: @player_for_new_ach, achievement: @achievement_for_new_ach)
    end
    # Then try to duplicate it
    duplicate_player_achievement = PlayerAchievement.new(player: @player_for_new_ach, achievement: @achievement_for_new_ach)
    assert_not duplicate_player_achievement.valid?
    assert_includes duplicate_player_achievement.errors[:player_id], "has already earned this achievement"
  end


  test "achieved_at should be set on creation" do
    player_achievement = PlayerAchievement.new(player: @player_for_new_ach, achievement: @achievement_for_new_ach)
    assert_nil player_achievement.achieved_at
    assert player_achievement.save, "Should save successfully. Errors: #{player_achievement.errors.full_messages.join(", ")}"
    assert_not_nil player_achievement.achieved_at
    assert_in_delta Time.current, player_achievement.achieved_at, 1.second
  end

  test "progress can be stored as json" do
    progress_data = { current: 5, total: 10 }
    player_achievement = PlayerAchievement.new(
      player: @player_for_new_ach,
      achievement: @achievement_for_new_ach,
      progress: progress_data
    )
    assert player_achievement.save, "Should save successfully. Errors: #{player_achievement.errors.full_messages.join(", ")}"
    assert_equal progress_data.with_indifferent_access, player_achievement.reload.progress
  end
end

require "test_helper"

class AchievementTest < ActiveSupport::TestCase
  def setup
    @achievement_params = {
      name: "Test Achievement",
      description: "This is a test achievement.",
      criteria: { type: "test", value: 1 },
      points: 10,
      icon_url: "test_icon.png"
    }
  end

  test "should be valid with all required attributes" do
    achievement = Achievement.new(@achievement_params)
    assert achievement.valid?
  end

  test "should require a name" do
    achievement = Achievement.new(@achievement_params.except(:name))
    assert_not achievement.valid?
    assert_includes achievement.errors[:name], "can't be blank"
  end

  test "name should be unique" do
    Achievement.create!(@achievement_params)
    achievement2 = Achievement.new(@achievement_params)
    assert_not achievement2.valid?
    assert_includes achievement2.errors[:name], "has already been taken"
  end

  test "should require a description" do
    achievement = Achievement.new(@achievement_params.except(:description))
    assert_not achievement.valid?
    assert_includes achievement.errors[:description], "can't be blank"
  end

  test "should require criteria" do
    achievement = Achievement.new(@achievement_params.except(:criteria))
    assert_not achievement.valid?
    assert_includes achievement.errors[:criteria], "can't be blank"
  end

  # test "points should be non-negative if present" do
  #   achievement = Achievement.new(@achievement_params.merge(points: -5))
  #   assert_not achievement.valid?
  #   assert_includes achievement.errors[:points], "must be greater than or equal to 0"

  #   achievement.points = 10
  #   assert achievement.valid?

  #   achievement.points = nil
  #   assert achievement.valid?
  # end

  test "can have many players through player_achievements" do
    achievement = Achievement.new(@achievement_params)
    assert_respond_to achievement, :players
    assert_respond_to achievement, :player_achievements
  end
end

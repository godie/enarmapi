require "test_helper"

class AchievementsControllerTest < ActionDispatch::IntegrationTest
  fixtures :achievements, :categories # Added categories because one achievement depends on it

  setup do
    # Using existing fixtures for achievements
    @achievement1 = achievements(:exams_completed_1)
    @achievement2 = achievements(:exams_completed_5)
  end

  test "should get index and list all achievements" do
    get achievements_url, as: :json
    assert_response :success

    response_json = JSON.parse(response.body)
    assert_equal Achievement.count, response_json.size

    achievement_names = response_json.map { |ach| ach["name"] }
    assert_includes achievement_names, @achievement1.name
    assert_includes achievement_names, @achievement2.name

    # Check that created_at and updated_at are not included
    response_json.each do |ach_json|
      assert_not ach_json.key?("created_at")
      assert_not ach_json.key?("updated_at")
    end
  end
end

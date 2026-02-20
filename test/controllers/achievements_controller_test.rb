require "test_helper"

class AchievementsControllerTest < ActionDispatch::IntegrationTest
  fixtures :achievements, :categories, :users

  setup do
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

    response_json.each do |ach_json|
      assert_not ach_json.key?("created_at")
      assert_not ach_json.key?("updated_at")
    end
  end

  test "should create achievement as admin" do
    assert_difference("Achievement.count", 1) do
      post achievements_url,
           params: {
             achievement: {
               name: "Nuevo Logro",
               description: "Descripción del logro.",
               icon_url: "icon.png",
               points: 25,
               criteria: { type: "exams_completed", count: 3 }
             }
           },
           headers: admin_auth_headers,
           as: :json
    end
    assert_response :created
    json = json_response
    assert_equal "Nuevo Logro", json["name"]
    assert_equal 25, json["points"]
    assert_equal "exams_completed", json["criteria"]["type"]
  end

  test "should not create achievement without admin auth" do
    assert_no_difference("Achievement.count") do
      post achievements_url,
           params: {
             achievement: {
               name: "Sin Auth",
               description: "Desc.",
               criteria: { type: "exams_completed", count: 1 }
             }
           },
           as: :json
    end
    assert_response :unauthorized
  end

  test "should update achievement as admin" do
    patch achievement_url(@achievement1),
          params: {
            achievement: { name: "Pionero Actualizado", points: 15 }
          },
          headers: admin_auth_headers,
          as: :json
    assert_response :success
    assert_equal "Pionero Actualizado", @achievement1.reload.name
    assert_equal 15, @achievement1.points
  end

  test "should destroy achievement as admin" do
    assert_difference("Achievement.count", -1) do
      delete achievement_url(@achievement2), headers: admin_auth_headers, as: :json
    end
    assert_response :no_content
  end
end

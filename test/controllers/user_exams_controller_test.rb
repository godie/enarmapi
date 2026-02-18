require "test_helper"

class UserExamsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :exams

  setup do
    @user = users(:admin)
    @exam = exams(:exam_one_urgencias)
    @auth_headers = admin_auth_headers(@user)
  end

  test "should get index" do
    get "/user_exams", headers: @auth_headers, as: :json
    assert_response :success
  end

  test "should create user_exam" do
    assert_difference("UserExam.count") do
      post "/user_exams", params: { exam_id: @exam.id }, headers: @auth_headers, as: :json
    end
    assert_response :created
  end
end

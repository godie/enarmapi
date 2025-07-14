require "test_helper"
require "webmock/minitest"

class AiControllerTest < ActionDispatch::IntegrationTest
  include AuthenticationHelpers
  fixtures :users

  setup do
    @auth_headers = admin_auth_headers(users(:admin))
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  test "should get generate_question" do
    stub_request(:post, "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent")
      .to_return(status: 200, body: "{\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"{\\\"question\\\":\\\"This is a generated question?
\\\",\\\"answers\\\":[{\\\"text\\\":\\\"This is a correct answer\\\",\\\"is_correct\\\":true},{\\\"text\\\":\\\"This is a wrong answer\\\",\\\"is_correct\\\":false}]}\"}]}}]}", headers: {})

    post "/ai/generate_question", params: { prompt: "test" }, headers: @auth_headers
    assert_response :success
  end

  test "should get generate_clinical_case" do
    stub_request(:post, "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent")
      .to_return(status: 200, body: "{\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"{\\\"name\\\":\\\"Generated Clinical Case\\\",\\\"description\\\":\\\"This is a generated clinical case.\\\",\\\"questions\\\":[{\\\"text\\\":\\\"This is a generated question?
\\\",\\\"answers\\\":[{\\\"text\\\":\\\"This is a correct answer\\\",\\\"is_correct\\\":true},{\\\"text\\\":\\\"This is a wrong answer\\\",\\\"is_correct\\\":false}]}]}\"}]}}]}", headers: {})

    post "/ai/generate_clinical_case", params: { prompt: "test" }, headers: @auth_headers
    assert_response :success
  end
end

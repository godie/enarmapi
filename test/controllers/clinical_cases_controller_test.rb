require "test_helper"

class ClinicalCasesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get clinical_cases_index_url
    assert_response :success
  end

  test "should get show" do
    get clinical_cases_show_url
    assert_response :success
  end

  test "should get create" do
    post clinical_cases_create_url
    assert_response :success
  end
end

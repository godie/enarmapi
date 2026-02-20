require "test_helper"

class AiControllerTest < ActionDispatch::IntegrationTest
  include AuthenticationHelpers
  fixtures :users

  setup do
    @auth_headers = admin_auth_headers(users(:admin))
  end

  test "should get generate_question" do
    fake_response_from_service = {
      "question" => "This is a mocked question?",
      "answers" => [
        { "text" => "Correct mock answer", "is_correct" => true },
        { "text" => "Wrong mock answer", "is_correct" => false }
      ]
    }
    GenerativeAiService.stubs(:generate_question).returns(fake_response_from_service)

    post "/ai/generate_question", params: { prompt: "test" }, headers: @auth_headers

    assert_response :success
    assert_equal fake_response_from_service.to_json, @response.body
  end

  test "should get generate_clinical_case" do
    fake_case = { "name" => "Mocked Case", "description" => "A case from a mock." }
    GenerativeAiService.stubs(:generate_clinical_case).returns(fake_case)

    post "/ai/generate_clinical_case", params: { prompt: "test" }, headers: @auth_headers

    assert_response :success
    assert_equal fake_case.to_json, @response.body
  end

  test "should bulk create exam from pdf" do
    category = Category.create!(name: "Test Category")
    fake_exam_data = {
      "exam_name" => "Mocked Exam",
      "clinical_cases" => [
        {
          "name" => "Case 1",
          "description" => "Description 1",
          "questions" => [
            {
              "text" => "Q1",
              "answers" => [
                { "text" => "A1" },
                { "text" => "A2" }
              ]
            }
          ]
        }
      ],
      "standalone_questions" => [
        {
          "text" => "Q2",
          "answers" => [
            { "text" => "A3" },
            { "text" => "A4" }
          ]
        }
      ]
    }

    GenerativeAiService.stubs(:parse_exam_from_pdf).returns(fake_exam_data)

    # Creating dummy file content since we are mockinf the service anyway
    pdf_content = "%PDF-1.0\n"
    pdf_file = Rack::Test::UploadedFile.new(StringIO.new(pdf_content), "application/pdf", true, original_filename: "test.pdf")

    assert_difference "Exam.count", 1 do
      assert_difference "ClinicalCase.count", 1 do
        assert_difference "Question.count", 2 do
          assert_difference "Answer.count", 4 do
            post "/ai/bulk_create_exam",
                 params: { file: pdf_file, category_id: category.id },
                 headers: @auth_headers
          end
        end
      end
    end

    assert_response :created
    json_response = JSON.parse(@response.body)
    assert_equal "Examen creado exitosamente", json_response["message"]

    exam = Exam.find(json_response["exam_id"])
    assert_equal "Mocked Exam", exam.name
    assert_equal 2, exam.questions.count
  end
end

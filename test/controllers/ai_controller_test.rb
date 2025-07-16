require "test_helper"
# Ya no necesitas webmock en este archivo si solo mockeas el servicio
# require "webmock/minitest"

class AiControllerTest < ActionDispatch::IntegrationTest
  include AuthenticationHelpers
  fixtures :users

  setup do
    @auth_headers = admin_auth_headers(users(:admin))
    # Ya no es necesario deshabilitar las conexiones de red con WebMock aquí
  end

  test "should get generate_question" do
    # 1. Define la respuesta falsa que quieres que tu servicio devuelva
    fake_response_from_service = {
      "question" => "This is a mocked question?",
      "answers" => [
        { "text" => "Correct mock answer", "is_correct" => true },
        { "text" => "Wrong mock answer", "is_correct" => false }
      ]
    }

    # 2. Intercepta la llamada al método de clase y haz que devuelva tu respuesta falsa
    #    Esto evita que se ejecute el código real de GenerativeAiService.generate_question
    GenerativeAiService.stubs(:generate_question).returns(fake_response_from_service)

    # 3. Llama a tu controlador como antes
    post "/ai/generate_question", params: { prompt: "test" }, headers: @auth_headers

    # 4. Verifica que la respuesta del controlador sea la esperada
    assert_response :success
    assert_equal fake_response_from_service.to_json, @response.body
  end

  # Puedes aplicar la misma lógica para el test de generate_clinical_case
  test "should get generate_clinical_case" do
    fake_case = { "name" => "Mocked Case", "description" => "A case from a mock." }
    GenerativeAiService.stubs(:generate_clinical_case).returns(fake_case)

    post "/ai/generate_clinical_case", params: { prompt: "test" }, headers: @auth_headers

    assert_response :success
    assert_equal fake_case.to_json, @response.body
  end
end

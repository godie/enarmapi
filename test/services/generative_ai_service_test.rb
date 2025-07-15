# test/services/generative_ai_service_test.rb
require "test_helper"
require "json" # Needed for JSON.parse

class GenerativeAiServiceTest < ActiveSupport::TestCase
  # This setup block runs before each test
  setup do
    # Define a mock client object that responds to generate_content
    @mock_gemini_client = Minitest::Mock.new

    # Define a mock response object that responds to .content
    @mock_response = Minitest::Mock.new

    # Stub Gemini.new to return our mock client
    # This ensures that whenever GenerativeAiService calls Gemini.new,
    # it gets our controlled mock object instead of a real Gemini client.
    Gemini.stub(:new, @mock_gemini_client) do
      # This block is where the actual test code will run,
      # with Gemini.new effectively stubbed.
      # However, we need to pass the stub into a block to ensure it's active.
      # For testing class methods that instantiate a client internally,
      # we structure the stub call around the method call itself or the setup.
    end
  end

  # Test for `generate_question`
  test "should generate a question in the correct JSON format" do
    prompt = "What is the capital of France?"

    # Define the expected JSON response from the Gemini API
    # This is what your mock_response.content should return
    expected_api_response_content = {
      "question": "What is the capital of France?",
      "answers": [
        { "text": "Berlin", "is_correct": false },
        { "text": "Madrid", "is_correct": false },
        { "text": "Paris", "is_correct": true },
        { "text": "Rome", "is_correct": false }
      ]
    }.to_json # Ensure it's a JSON string

    # Set the expectation for @mock_response.content to return the JSON string
    @mock_response.expect :content, expected_api_response_content

    # Set the expectation for @mock_gemini_client.generate_content
    # It should be called once with any arguments, and return our mock_response.
    @mock_gemini_client.expect :generate_content, @mock_response, [ { contents: { role: "user", parts: { text: "Generate a multiple choice question with 4 answers based on the following prompt: #{prompt}. The response should be a JSON object with the following structure: {\"question\": \"...\", \"answers\": [{\"text\": \"...\", \"is_correct\": boolean}, ...]}" } } } ]

    # Now, stub Gemini.new around the service call
    # This ensures that `Gemini.new` returns our `@mock_gemini_client`
    # and that client's `generate_content` returns `@mock_response`.
    Gemini.stub(:new, @mock_gemini_client) do
      actual_response = GenerativeAiService.generate_question(prompt)

      # Assert that the service's output matches the expected parsed JSON
      expected_parsed_response = JSON.parse(expected_api_response_content)
      assert_equal expected_parsed_response, actual_response
    end

    # Verify that all expectations on the mocks were met
    @mock_gemini_client.verify
    @mock_response.verify
  end

  # Test for `generate_clinical_case`
  test "should generate a clinical case in the correct JSON format" do
    prompt = "A patient presenting with severe headache and blurred vision."

    # Define the expected JSON response from the Gemini API for a clinical case
    expected_api_response_content = {
      "name": "Caso de Migraña con Aura",
      "description": "Paciente de 35 años que acude a urgencias por cefalea intensa hemicraneal derecha, pulsátil, acompañada de fotofobia, fonofobia y náuseas. Precede al dolor una alteración visual con zigzag luminoso de 15 minutos de duración.",
      "questions": [
        {
          "text": "¿Cuál es el diagnóstico más probable basado en la descripción?",
          "answers": [
            { "text": "Accidente Cerebrovascular", "is_correct": false },
            { "text": "Migraña con aura", "is_correct": true },
            { "text": "Cefalea tensional", "is_correct": false },
            { "text": "Neuralgia del trigémino", "is_correct": false }
          ]
        },
        {
          "text": "¿Qué tratamiento agudo sería el más adecuado inicialmente?",
          "answers": [
            { "text": "Antibióticos", "is_correct": false },
            { "text": "Paracetamol solo", "is_correct": false },
            { "text": "Triptán oral y AINE", "is_correct": true },
            { "text": "Anticoagulantes", "is_correct": false }
          ]
        },
        {
          "text": "¿Qué factor precipitante común debería investigarse en este paciente?",
          "answers": [
            { "text": "Consumo excesivo de alcohol", "is_correct": false },
            { "text": "Estrés", "is_correct": true },
            { "text": "Ejercicio vigoroso", "is_correct": false },
            { "text": "Exposición solar prolongada", "is_correct": false }
          ]
        }
      ]
    }.to_json # Ensure it's a JSON string

    # Set the expectation for @mock_response.content to return the JSON string
    @mock_response.expect :content, expected_api_response_content

    # Set the expectation for @mock_gemini_client.generate_content
    @mock_gemini_client.expect :generate_content, @mock_response, [ { contents: { role: "user", parts: { text: "Generate a clinical case with a name, a description, and 3 multiple choice questions with 4 answers each based on the following prompt: #{prompt}. The response should be a JSON object with the following structure: {\"name\": \"...\", \"description\": \"...\", \"questions\": [{\"text\": \"...\", \"answers\": [{\"text\": \"...\", \"is_correct\": boolean}, ...]}, ...]}" } } } ]

    Gemini.stub(:new, @mock_gemini_client) do
      actual_response = GenerativeAiService.generate_clinical_case(prompt)

      # Assert that the service's output matches the expected parsed JSON
      expected_parsed_response = JSON.parse(expected_api_response_content)
      assert_equal expected_parsed_response, actual_response
    end

    # Verify that all expectations on the mocks were met
    @mock_gemini_client.verify
    @mock_response.verify
  end
end

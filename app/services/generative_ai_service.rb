require "gemini-ai"
require "base64"

class GenerativeAiService
    def self.client(model: "gemini-1.5-flash")
        Gemini.new(
            credentials: {
                service: "generative-language-api",
                api_key: ENV["GOOGLE_API_KEY"]
            },
            options: { model: model, server_sent_events: true }
        )
    end

    def self.generate_question(prompt)
        response = client.generate_content(
            { contents: { role: "user", parts: { text: "Generate a multiple choice question with 4 answers based on the following prompt: #{prompt}. The response should be a JSON object with the following structure: {\"question\": \"...\", \"answers\": [{\"text\": \"...\", \"is_correct\": boolean}, ...]}" } } }
        )
        JSON.parse(response.content)
    end

    def self.generate_clinical_case(prompt)
        response = client.generate_content(
            { contents: { role: "user", parts: { text: "Generate a clinical case with a name, a description, and 3 multiple choice questions with 4 answers each based on the following prompt: #{prompt}. The response should be a JSON object with the following structure: {\"name\": \"...\", \"description\": \"...\", \"questions\": [{\"text\": \"...\", \"answers\": [{\"text\": \"...\", \"is_correct\": boolean}, ...]}, ...]}" } } }
        )
        JSON.parse(response.content)
    end

    def self.parse_pdf_to_exam(file)
        file_content = Base64.strict_encode64(file.read)

        prompt = <<~PROMPT
          Analiza el documento PDF adjunto y extrae la información para crear un examen médico.
          El examen puede contener casos clínicos (que tienen un nombre, una descripción y una o más preguntas) y preguntas sueltas (que no pertenecen a ningún caso clínico).
          Para cada pregunta, extrae las opciones de respuesta.
          IMPORTANTE:
          1. Todas las respuestas deben tener el campo 'is_correct' en false.
          2. Si encuentras una imagen o figura en el documento, descríbela dentro del texto del caso clínico o de la pregunta usando el formato [IMAGEN: descripción detallada de la imagen].
          3. Devuelve la información en formato JSON con la siguiente estructura:
          {
            "exam_name": "Nombre del examen",
            "clinical_cases": [
              {
                "name": "Nombre del caso clínico",
                "description": "Descripción del caso clínico...",
                "questions": [
                  {
                    "text": "Texto de la pregunta...",
                    "answers": [
                      { "text": "Opción A", "is_correct": false },
                      ...
                    ]
                  }
                ]
              }
            ],
            "standalone_questions": [
              {
                "text": "Texto de la pregunta...",
                "answers": [
                  { "text": "Opción A", "is_correct": false },
                  ...
                ]
              }
            ]
          }
        PROMPT

        response = client.generate_content(
          {
            contents: {
              role: "user",
              parts: [
                { text: prompt },
                {
                  inline_data: {
                    mime_type: "application/pdf",
                    data: file_content
                  }
                }
              ]
            }
          }
        )

        # Remove markdown code blocks if present
        json_content = response.content.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
        JSON.parse(json_content)
    rescue => e
        Rails.logger.error "Error parsing PDF with AI: #{e.message}"
        raise e
    end
end

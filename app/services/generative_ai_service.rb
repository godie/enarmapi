require "gemini-ai"

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

    def self.parse_exam_from_pdf(pdf_base64)
        prompt = <<~PROMPT
          Analyze the attached PDF and extract all clinical cases and standalone questions.
          A clinical case is a description followed by one or more related questions.
          A standalone question is a question not linked to a specific clinical case.

          Return a JSON object with the following structure:
          {
            "exam_name": "Name of the exam or document",
            "clinical_cases": [
              {
                "name": "Title or summary of the case",
                "description": "Full description of the clinical case",
                "questions": [
                  {
                    "text": "Question text",
                    "answers": [
                      {"text": "Answer choice 1"},
                      {"text": "Answer choice 2"},
                      {"text": "Answer choice 3"},
                      {"text": "Answer choice 4"}
                    ]
                  }
                ]
              }
            ],
            "standalone_questions": [
              {
                "text": "Question text",
                "answers": [
                   {"text": "Answer 1"},
                   {"text": "Answer 2"},
                   {"text": "Answer 3"},
                   {"text": "Answer 4"}
                ]
              }
            ]
          }
          IMPORTANT: Return ONLY the JSON object.
        PROMPT

        response = client.generate_content({
            contents: {
                role: "user",
                parts: [
                    { inline_data: { mime_type: "application/pdf", data: pdf_base64 } },
                    { text: prompt }
                ]
            }
        })

        # Extract JSON if it's wrapped in markdown blocks
        content = response.content
        if content =~ /```json\n?(.*?)\n?```/m
            content = $1
        end

        begin
          JSON.parse(content)
        rescue JSON::ParserError
          # Fallback if AI output is not clean JSON
          { "error" => "Failed to parse AI response", "content" => content }
        end
    end
end

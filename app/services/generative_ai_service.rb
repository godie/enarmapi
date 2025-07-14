require 'gemini-ai'

class GenerativeAiService
    def self.generate_question(prompt)
        client = Gemini.new(
            credentials: {
                service: 'generative-language-api',
                api_key: ENV['GOOGLE_API_KEY']
            },
            options: { model: 'gemini-pro', server_sent_events: true }
        )
        response = client.generate_content(
            { contents: { role: 'user', parts: { text: "Generate a multiple choice question with 4 answers based on the following prompt: #{prompt}. The response should be a JSON object with the following structure: {\"question\": \"...\", \"answers\": [{\"text\": \"...\", \"is_correct\": boolean}, ...]}" } } }
        )
        JSON.parse(response.content)
    end

    def self.generate_clinical_case(prompt)
        client = Gemini.new(
            credentials: {
                service: 'generative-language-api',
                api_key: ENV['GOOGLE_API_KEY']
            },
            options: { model: 'gemini-pro', server_sent_events: true }
        )
        response = client.generate_content(
            { contents: { role: 'user', parts: { text: "Generate a clinical case with a name, a description, and 3 multiple choice questions with 4 answers each based on the following prompt: #{prompt}. The response should be a JSON object with the following structure: {\"name\": \"...\", \"description\": \"...\", \"questions\": [{\"text\": \"...\", \"answers\": [{\"text\": \"...\", \"is_correct\": boolean}, ...]}, ...]}" } } }
        )
        JSON.parse(response.content)
    end
end

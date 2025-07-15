require_relative "../services/generative_ai_service"
class AiController < ApplicationController
    before_action :authenticate_admin!
    def generate_question
        prompt = params[:prompt]
        response = GenerativeAiService.generate_question(prompt)
        render json: response
    end

    def generate_clinical_case
        prompt = params[:prompt]
        response = GenerativeAiService.generate_clinical_case(prompt)
        render json: response
    end
end

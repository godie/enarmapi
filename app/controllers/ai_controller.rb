require "base64"
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

    def bulk_create_exam
        file = params[:file]
        category_id = params[:category_id]

        if file.nil? || category_id.nil?
            return render json: { error: "Archivo y categoría son requeridos" }, status: :bad_request
        end

        parsed_data = GenerativeAiService.parse_pdf_to_exam(file)

        ActiveRecord::Base.transaction do
            @exam = Exam.create!(
                name: parsed_data["exam_name"],
                category_id: category_id
            )

            if parsed_data["clinical_cases"]
                parsed_data["clinical_cases"].each do |cc_data|
                    clinical_case = ClinicalCase.create!(
                        name: cc_data["name"],
                        description: cc_data["description"],
                        category_id: category_id
                    )

                    cc_data["questions"].each do |q_data|
                        question = clinical_case.questions.create!(
                            text: q_data["text"]
                        )

                        q_data["answers"].each do |a_data|
                            question.answers.create!(
                                text: a_data["text"],
                                is_correct: false
                            )
                        end

                        @exam.exam_questions.create!(
                            question: question,
                            position: @exam.exam_questions.count + 1
                        )
                    end
                end
            end

            if parsed_data["standalone_questions"]
                parsed_data["standalone_questions"].each do |q_data|
                    question = Question.create!(
                        text: q_data["text"],
                        category_id: category_id
                    )

                    q_data["answers"].each do |a_data|
                        question.answers.create!(
                            text: a_data["text"],
                            is_correct: false
                        )
                    end

                    @exam.exam_questions.create!(
                        question: question,
                        position: @exam.exam_questions.count + 1
                    )
                end
            end
        end

        render json: @exam.as_json(include: {
            exam_questions: {
                include: {
                    question: {
                        include: [ :answers, :clinical_case ]
                    }
                }
            }
        }), status: :created
    rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
    end
end

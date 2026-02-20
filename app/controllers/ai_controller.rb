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
            return render json: { error: "Falta el archivo o el category_id" }, status: :bad_request
        end

        begin
            pdf_base64 = Base64.strict_encode64(file.read)
            exam_data = GenerativeAiService.parse_exam_from_pdf(pdf_base64)

            if exam_data["error"]
                return render json: { error: exam_data["error"], detail: exam_data["content"] }, status: :unprocessable_entity
            end

            @exam = nil
            ActiveRecord::Base.transaction do
                @exam = Exam.create!(
                    name: exam_data["exam_name"] || "Examen Importado #{Time.now.to_i}",
                    category_id: category_id,
                    description: "Importado automáticamente desde PDF"
                )

                # Standalone questions
                (exam_data["standalone_questions"] || []).each do |q_data|
                    question = Question.create!(
                        text: q_data["text"],
                        category_id: category_id
                    )

                    (q_data["answers"] || []).each do |a_data|
                        question.answers.create!(
                            text: a_data["text"],
                            is_correct: false # Todas las respuestas incorrectas para revisión manual
                        )
                    end

                    ExamQuestion.create!(
                        exam: @exam,
                        question: question
                    )
                end

                # Clinical Cases
                (exam_data["clinical_cases"] || []).each do |cc_data|
                    clinical_case = ClinicalCase.create!(
                        name: cc_data["name"] || "Caso Clínico",
                        description: cc_data["description"],
                        category_id: category_id
                    )

                    (cc_data["questions"] || []).each do |q_data|
                        question = Question.create!(
                            text: q_data["text"],
                            clinical_case: clinical_case
                        )

                        (q_data["answers"] || []).each do |a_data|
                            question.answers.create!(
                                text: a_data["text"],
                                is_correct: false
                            )
                        end

                        ExamQuestion.create!(
                            exam: @exam,
                            question: question
                        )
                    end
                end
            end

            render json: {
                message: "Examen creado exitosamente",
                exam_id: @exam.id,
                exam_name: @exam.name
            }, status: :created

        rescue => e
            render json: { error: "Error al procesar el examen: #{e.message}" }, status: :unprocessable_entity
        end
    end
end

class UserAnswersController < ApplicationController
  before_action :authenticate_user!

  def create
    successful_saves = true
    @user_answers_records = []

    user_answers_params.each do |answer_data|
      user_answer = @current_user.user_answers.build(answer_data)
      if user_answer.save
        @user_answers_records << user_answer
      else
        successful_saves = false
        @errors = user_answer.errors.full_messages
        break
      end
    end

    if successful_saves
      # Alias para service si aún existe con nombre viejo
      player_for_service = @current_user
      unlocked_achievements = Achievements::UnlockService.new(player_for_service).call

      # Optimización para evitar N+1
      @user_answers_records = UserAnswer.where(id: @user_answers_records.map(&:id)).includes(question: :answers, answer: {})

      results = @user_answers_records.map do |ua|
        correct_answer = ua.question.answers.find(&:is_correct)
        {
          question_id: ua.question_id,
          answer_id: ua.answer_id,
          is_correct: ua.is_correct,
          explanation: ua.answer.description,
          correct_answer: {
            id: correct_answer&.id,
            text: correct_answer&.text,
            explanation: correct_answer&.description
          }
        }
      end

      response_message = "Respuestas guardadas correctamente!"
      response_message += " ¡Has desbloqueado #{unlocked_achievements.count} nuevos logros!" if unlocked_achievements.any?

      render json: {
        message: response_message,
        results: results,
        unlocked_achievements: unlocked_achievements.map { |ach| { id: ach.id, name: ach.name } }
      }, status: :created
    else
      render json: { errors: @errors || "No se pudieron guardar algunas respuestas." }, status: :unprocessable_entity
    end
  end

  def index
    @user_answers = @current_user.user_answers
    render json: @user_answers
  end

  private

  def user_answers_params
     params.require(:user_answers).map do |answer_param|
        answer_param.permit(:question_id, :answer_id)
      end
  end
end

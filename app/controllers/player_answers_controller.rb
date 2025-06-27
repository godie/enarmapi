class PlayerAnswersController < ApplicationController
  before_action :authenticate_player!

  def create
    # Use player_answers_params to permit the allowed attributes
    # We expect an array of answer hashes, so we'll iterate
    successful_saves = true
    @player_answers_records = []

    player_answers_params.each do |answer_data|
      player_answer = @current_player.player_answers.build(answer_data)
      if player_answer.save
        @player_answers_records << player_answer
      else
        # If any individual answer fails to save, we might want to collect errors
        successful_saves = false
        # For simplicity, we'll stop and report the first error, or you can collect all errors
        @errors = player_answer.errors.full_messages
        break # Exit the loop if one fails
      end
    end

    if successful_saves
      # Attempt to unlock achievements after successfully saving answers
      unlocked_achievements = Achievements::UnlockService.new(@current_player).call

      response_message = "Answers saved successfully!"
      response_message += " You've unlocked #{unlocked_achievements.count} new achievement(s)!" if unlocked_achievements.any?

      render json: {
        message: response_message,
        player_answer_ids: @player_answers_records.map(&:id),
        unlocked_achievements: unlocked_achievements.map { |ach| { id: ach.id, name: ach.name } }
      }, status: :created
    else
      render json: { errors: @errors || "Some answers could not be saved." }, status: :unprocessable_entity
    end
  end

  def index
    @player_answers = @current_player.player_answers
    render json: @player_answers
  end

  private
  def player_answers_params
     params.require(:player_answers).map do |answer_param|
        answer_param.permit(:question_id, :answer_id)
      end
  end
end

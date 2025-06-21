class PlayerAnswersController < ApplicationController
  before_action :authenticate_player!
  def create
    @current_player.player_answers.build(params[:player_answers])
    if @current_player.save
      render json: { message: "saved" }, status: :created
    else
      render json: { error: "errors" }, status: :unprocessable_entity
    end
  end

  def index
  end
end

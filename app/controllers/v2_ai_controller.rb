class V2AiController < ApplicationController
  before_action :authenticate_admin!

  def generate_flashcards
    topic = params[:topic]
    count = params[:count] || 5
    difficulty = params[:difficulty] || "intermedio"

    suggestions = GenerativeAiService.generate_flashcards(topic, count, difficulty)

    flashcards = suggestions.map do |s|
      Flashcard.create!(
        front: s["front"],
        back: s["back"],
        status: "waiting_approval"
      )
    end

    render json: flashcards
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

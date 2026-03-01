class FlashcardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_flashcard, only: [ :show, :review ]

  # GET /flashcards
  def index
    @flashcards = Flashcard.all
    @flashcards = @flashcards.where(category_id: params[:category_id]) if params[:category_id].present?
    render json: @flashcards
  end

  # GET /flashcards/:id
  def show
    render json: @flashcard
  end

  # GET /flashcards/due
  def due
    @due_cards = @current_user.user_flashcards.due.includes(:flashcard)
    render json: @due_cards.as_json(include: :flashcard)
  end

  # POST /flashcards/:id/review
  def review
    user_flashcard = @current_user.user_flashcards.find_or_initialize_by(flashcard: @flashcard)
    quality = params[:quality].to_i

    if user_flashcard.review(quality)
      render json: user_flashcard
    else
      render json: user_flashcard.errors, status: :unprocessable_entity
    end
  end

  private

  def set_flashcard
    @flashcard = Flashcard.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Flashcard not found" }, status: :not_found
  end
end

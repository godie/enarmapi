class V2FlashcardsController < ApplicationController
  before_action :authenticate_user!

  def create
    flashcard = Flashcard.new(flashcard_params)
    flashcard.user = Current.user
    flashcard.status = "published" # Assuming user created ones are published immediately

    if flashcard.save
      # Automatically add to user's cards
      Current.user.user_flashcards.create!(flashcard: flashcard)
      render json: flashcard, status: :created
    else
      render json: { errors: flashcard.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def review
    # Obtener flashcards pendientes de repaso para el usuario actual
    user_flashcards = Current.user.user_flashcards.due.limit(20)

    render json: {
      flashcards: user_flashcards.map { |uf|
        {
          id: uf.flashcard.id,
          front: uf.flashcard.front,
          back: uf.flashcard.back,
          category: uf.flashcard.category&.name || "General"
        }
      }
    }
  end

  def answer
    user_flashcard = Current.user.user_flashcards.find_by(flashcard_id: params[:id])

    if user_flashcard
      user_flashcard.review(params[:quality].to_i)
      render json: { message: "Respuesta registrada", next_review: user_flashcard.next_review }
    else
      render json: { error: "Flashcard no encontrada para este usuario" }, status: :not_found
    end
  end

  private

  def flashcard_params
    # Mapear specialtyId a category_id
    p = params.permit(:front, :back, :specialtyId, :tags)
    {
      front: p[:front],
      back: p[:back],
      category_id: p[:specialtyId],
      tags: p[:tags]
    }
  end
end

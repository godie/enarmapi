class V2FlashcardsController < ApplicationController
  before_action :authenticate_user!

  def review
    # Obtener flashcards pendientes de repaso para el usuario actual
    user_flashcards = Current.user.user_flashcards.due.limit(20)

    # Si no hay pendientes, podríamos sugerir algunas nuevas o simplemente enviar vacío
    # El requisito dice que el backend decide según SRS

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
end

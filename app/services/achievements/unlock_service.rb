# frozen_string_literal: true

module Achievements
  class UnlockService
    def initialize(player)
      @player = player
    end

    def call
      unlocked_achievements = []
      Achievement.find_each do |achievement|
        next if @player.achievements.exists?(achievement.id) # Ya lo tiene

        if criteria_met?(achievement)
          PlayerAchievement.create(player: @player, achievement: achievement)
          unlocked_achievements << achievement
        end
      end
      unlocked_achievements
    end

    private

    def criteria_met?(achievement)
      criteria = achievement.criteria.with_indifferent_access
      type = criteria[:type]

      case type
      when "exams_completed"
        check_exams_completed(criteria)
      when "category_accuracy"
        check_category_accuracy(criteria)
      when "correct_streak" # A definir cómo calcular esto, podría ser más complejo
        # check_correct_streak(criteria)
        false # Placeholder
      when "category_completion" # A definir cómo calcular esto
        # check_category_completion(criteria)
        false # Placeholder
      else
        Rails.logger.warn "Unknown achievement criteria type: #{type} for achievement #{achievement.id}"
        false
      end
    end

    def check_exams_completed(criteria)
      required_count = criteria[:count].to_i
      @player.taken_exams.count >= required_count
    end

    def check_category_accuracy(criteria)
      category_id = criteria[:category_id].to_i
      accuracy_threshold = criteria[:accuracy_threshold].to_f
      min_exams_in_category = (criteria[:min_exams_in_category] || 1).to_i

      # 1. Contar exámenes distintos tomados por el jugador en esa categoría
      # Un PlayerExam representa un intento de examen por un jugador.
      # Si un jugador puede tomar el mismo examen múltiples veces, player_exams contará cada intento.
      # Para "número de exámenes distintos en la categoría", necesitamos contar los exam_id únicos.

      # Asegurémonos que player_exams se una con exam para filtrar por category_id
      player_exams_in_category = @player.player_exams.joins(:exam)
                                        .where(exams: { category_id: category_id })

      # Contar el número de exámenes *distintos* que el jugador ha tomado en esa categoría.
      # Esto es importante si un jugador puede reintentar el mismo examen.
      # Si PlayerExam tiene completed_at, podríamos querer filtrar solo los completados.
      # Por ahora, contamos player_exams distintos basados en exam_id.
      distinct_exams_taken_count = player_exams_in_category.select(:exam_id).distinct.count

      return false if distinct_exams_taken_count < min_exams_in_category

      # 2. Calcular precisión promedio en esa categoría para las preguntas respondidas por el jugador.
      # Las PlayerAnswers deben estar asociadas a preguntas de esa categoría.
      # Necesitamos las player_answers para preguntas de esa categoría
      correct_answers_in_category = @player.player_answers
                                           .joins(question: { clinical_case: :category })
                                           .where(categories: { id: category_id }, is_correct: true)
                                           .count

      total_answers_in_category = @player.player_answers
                                         .joins(question: { clinical_case: :category })
                                         .where(categories: { id: category_id })
                                         .count

      return false if total_answers_in_category.zero?

      accuracy = (correct_answers_in_category.to_f / total_answers_in_category) * 100
      accuracy >= accuracy_threshold
    end

    # TODO: Implementar check_correct_streak y check_category_completion
    # check_correct_streak requeriría probablemente un seguimiento más detallado de las respuestas
    # o una nueva tabla para rachas.
    # check_category_completion requeriría verificar que todas las preguntas/casos de una categoría
    # han sido respondidos/completados correctamente.
  end
end

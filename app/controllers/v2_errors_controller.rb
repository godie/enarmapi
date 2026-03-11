class V2ErrorsController < ApplicationController
  before_action :authenticate_user!

  def summary
    # Preguntas fallidas del usuario
    failed_answers = Current.user.user_answers.incorrect.includes(question: [ :answers, { clinical_case: :category } ]).recent

    # Agrupar por especialidad (categoría) para el resumen
    specialties_count = failed_answers.each_with_object(Hash.new(0)) do |ua, hash|
      category = ua.question.effective_category
      hash[category] += 1 if category
    end

    most_failed_specialties = specialties_count.map do |category, count|
      { id: "esp#{category.id}", name: category.name, count: count }
    end.sort_by { |s| -s[:count] }.take(5)

    recent_failed_questions = failed_answers.take(10).map do |ua|
      {
        id: "q#{ua.question.id}",
        question: ua.question.text,
        correctAnswer: ua.question.answers.find(&:is_correct?)&.text,
        userAnswer: ua.answer.text,
        explanation: ua.answer.description # O la del correct answer si estuviera ahí
      }
    end

    render json: {
      mostFailedSpecialties: most_failed_specialties,
      recentFailedQuestions: recent_failed_questions
    }
  end
end

class Player < ApplicationRecord
  has_many :player_answers
  has_many :practiced_questions, through: :player_answers, source: :question
  has_many :answers, through: :player_answers
  has_many :player_exams
  has_many :taken_exams, through: :player_exams, source: :exam

  # Validaciones
  validates :facebook_id, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Métodos de estadísticas
  def stats
    {
      total_answers: player_answers.count,
      correct_answers: player_answers.correct.count,
      incorrect_answers: player_answers.incorrect.count,
      accuracy_percentage: calculate_accuracy,
      questions_answered: answered_questions.distinct.count,
      last_activity: player_answers.maximum(:created_at)
    }
  end

  def calculate_accuracy
    return 0 if player_answers.count.zero?
    ((player_answers.correct.count.to_f / player_answers.count) * 100).round(2)
  end

  def answered?(question)
    player_answers.exists?(question: question)
  end

  def answer_for(question)
    player_answers.find_by(question: question)
  end

  # Para práctica - obtener preguntas no respondidas
  def unanswered_questions
    Question.where.not(id: answered_questions.select(:id))
  end

  def questions_by_category
    answered_questions
      .joins(clinical_case: :category)
      .group("categories.name")
      .count
  end
end

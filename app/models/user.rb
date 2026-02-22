class User < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  has_secure_password validations: false

  enum :role, { player: 0, admin: 1, specialist: 2 }, default: :player

  has_one :specialist_profile, dependent: :destroy
  has_many :sent_messages, class_name: "Message", foreign_key: "sender_id", dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: "receiver_id", dependent: :destroy

  has_many :user_answers, dependent: :destroy
  has_many :practiced_questions, through: :user_answers, source: :question
  has_many :answers, through: :user_answers
  has_many :user_exams, dependent: :destroy
  has_many :taken_exams, through: :user_exams, source: :exam

  has_many :user_achievements, dependent: :destroy
  has_many :achievements, through: :user_achievements
  has_many :clinical_cases, dependent: :nullify, foreign_key: :user_id

  has_many :user_flashcards, dependent: :destroy
  has_many :flashcards, through: :user_flashcards

  # Validaciones
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: VALID_EMAIL_REGEX }
  validates :username, uniqueness: { case_sensitive: false }, allow_nil: true
  validates :facebook_id, uniqueness: true, allow_nil: true
  validates :google_id, uniqueness: true, allow_nil: true
  validates :password, length: { minimum: 6 }, confirmation: true, if: -> { password.present? }

  # Métodos de estadísticas
  def stats
    {
      total_answers: user_answers.count,
      correct_answers: user_answers.correct.count,
      incorrect_answers: user_answers.incorrect.count,
      accuracy_percentage: calculate_accuracy,
      questions_answered: answered_questions.distinct.count,
      last_activity: user_answers.maximum(:created_at)
    }
  end

  def calculate_accuracy
    return 0 if user_answers.count.zero?
    ((user_answers.correct.count.to_f / user_answers.count) * 100).round(2)
  end

  def total_points
    achievements.sum(:points) || 0
  end

  def answered?(question)
    user_answers.exists?(question: question)
  end

  def answer_for(question)
    user_answers.find_by(question: question)
  end

  def answered_questions
    Question.joins(:user_answers).where(user_answers: { user_id: id })
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

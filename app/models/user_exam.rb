class UserExam < ApplicationRecord
  belongs_to :user
  belongs_to :exam
  has_many :user_exam_answers
  has_many :exam_questions, through: :exam

  scope :complete, -> { where(status: "completed") }
  scope :in_progress, -> { where(status: "in_progress") }

  def calculate_score
    user_exam_answers.sum(:points_earned)
  end
end

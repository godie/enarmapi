class PlayerExam < ApplicationRecord
  belongs_to :player
  belongs_to :exam
  has_many :player_exam_answers
  has_many :exam_questions, through: :exam

  scope :complete, -> { where(status: "completed") }
  scope :in_progress, -> { where(status: "in_progress") }

  def calculate_score
    player_exam_answers.sum(:points_earned)
  end
end

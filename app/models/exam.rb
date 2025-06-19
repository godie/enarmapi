class Exam < ApplicationRecord
  has_many :exam_questions, -> { order(:position) }
  has_many :questions, through: :exam_questions
  has_many :player_exams

  def total_points
    exam_questions.sum(:points)
  end
end

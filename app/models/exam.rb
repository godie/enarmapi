class Exam < ApplicationRecord
  has_many :exam_questions, -> { order(:position) }, dependent: :destroy
  has_many :questions, through: :exam_questions
  has_many :player_exams, dependent: :destroy # Assuming player_exams should also be destroyed

  accepts_nested_attributes_for :exam_questions, allow_destroy: true

  validates :name, presence: true
  # validates :description, presence: true # Optional: Add if description should also be mandatory

  def total_points
    exam_questions.sum(:points)
  end
end

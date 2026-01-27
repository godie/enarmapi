class Exam < ApplicationRecord
  belongs_to :category

  has_many :exam_questions, -> { order(:position) }, dependent: :destroy, inverse_of: :exam
  has_many :questions, through: :exam_questions
  has_many :user_exams, dependent: :destroy
  has_many :users, through: :user_exams

  accepts_nested_attributes_for :exam_questions, allow_destroy: true

  validates :name, presence: true

  def total_points
    exam_questions.sum(:points)
  end
end

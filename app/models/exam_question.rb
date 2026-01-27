class ExamQuestion < ApplicationRecord
  belongs_to :exam
  belongs_to :question
  has_many :user_exam_answers, dependent: :destroy

  validates :question_id, presence: true
  validates :question_id, uniqueness: { scope: :exam_id, message: "ya ha sido añadida a este examen" }
end

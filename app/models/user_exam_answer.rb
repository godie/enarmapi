class UserExamAnswer < ApplicationRecord
  belongs_to :user_exam
  belongs_to :exam_question
  belongs_to :answer

  validates :user_exam_id, presence: true
  validates :exam_question_id, presence: true

  validates :exam_question_id, uniqueness: { scope: :user_exam_id, message: "ya ha sido respondida en este examen" }
end

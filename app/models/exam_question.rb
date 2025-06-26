class ExamQuestion < ApplicationRecord
  belongs_to :exam
  belongs_to :question
  has_many :player_exam_answers

  # validates :exam_id, presence: true
  validates :question_id, presence: true

  validates :question_id, uniqueness: { scope: :exam_id, message: "has already been added to this exam" }
  # act_as_list scope: :exam
end

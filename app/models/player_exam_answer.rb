class PlayerExamAnswer < ApplicationRecord
  belongs_to :player_exam
  belongs_to :exam_question
  belongs_to :answer

  validates :player_exam_id, presence: true
  validates :exam_question_id, presence: true

  validates :exam_question_id, uniqueness: { scope: :player_exam_id, message: "has already been answered for this player exam" }
end

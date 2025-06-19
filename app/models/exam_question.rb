class ExamQuestion < ApplicationRecord
  belongs_to :exam
  belongs_to :question
  has_many :player_exam_answers

  # act_as_list scope: :exam
end

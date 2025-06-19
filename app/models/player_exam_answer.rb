class PlayerExamAnswer < ApplicationRecord
  belongs_to :player_exam
  belongs_to :exam_question
  belongs_to :answer
end

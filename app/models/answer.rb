class Answer < ApplicationRecord
  belongs_to :question
  has_many :player_answers
end

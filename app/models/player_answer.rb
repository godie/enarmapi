# app/models/player_answer.rb
class PlayerAnswer < ApplicationRecord
  belongs_to :player
  belongs_to :question
  belongs_to :answer

  validates :player_id, uniqueness: { scope: :question_id,
    message: "ya ha respondido esta pregunta" }

  validates :question_id, presence: true
  validates :answer_id, presence: true

  # Callbacks
  before_create :set_correctness
  #after_create :update_player_stats
  
  # Scopes
  scope :correct, -> { where(is_correct: true) }
  scope :incorrect, -> { where(is_correct: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_question, ->(question_id) { where(question_id: question_id) }
  

  private

  def set_correctness
    self.is_correct = answer.correct? if answer
  end
  def update_player_stats
  end
end

class UserAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :question
  belongs_to :answer


  validates :question_id, presence: true
  validates :answer_id, presence: true

  # Callbacks
  before_create :set_correctness

  # Scopes
  scope :correct, -> { where(is_correct: true) }
  scope :incorrect, -> { where(is_correct: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_question, ->(question_id) { where(question_id: question_id) }

  private

  def set_correctness
    self.is_correct = answer.is_correct? if answer
  end
end

class Flashcard < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :user, optional: true # Creator

  has_many :user_flashcards, dependent: :destroy
  has_many :users, through: :user_flashcards

  validates :front, :back, presence: true

  # status: pending, published, deleted, waiting_approval, not_approved
  STATUSES = %w[pending published deleted waiting_approval not_approved].freeze
  validates :status, inclusion: { in: STATUSES }, allow_nil: true

  def tag_list
    tags&.split(",")&.map(&:strip) || []
  end
end

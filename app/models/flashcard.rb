class Flashcard < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :user, optional: true # Creator

  has_many :user_flashcards, dependent: :destroy
  has_many :users, through: :user_flashcards

  validates :front, :back, presence: true
end

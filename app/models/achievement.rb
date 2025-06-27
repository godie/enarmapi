class Achievement < ApplicationRecord
  has_many :player_achievements, dependent: :destroy
  has_many :players, through: :player_achievements

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :criteria, presence: true
  # validates :points, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
end

class SpecialistProfile < ApplicationRecord
  belongs_to :user

  validates :specialty, :bio, presence: true
  validates :user_id, uniqueness: true
end

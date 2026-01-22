class UserAchievement < ApplicationRecord
  belongs_to :user
  belongs_to :achievement

  validates :user_id, uniqueness: { scope: :achievement_id, message: "ya ha ganado este logro" }

  before_create :set_achieved_at

  private

  def set_achieved_at
    self.achieved_at ||= Time.current
  end
end

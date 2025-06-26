class PlayerAchievement < ApplicationRecord
  belongs_to :player
  belongs_to :achievement

  validates :player_id, uniqueness: { scope: :achievement_id, message: "has already earned this achievement" }

  before_create :set_achieved_at

  private

  def set_achieved_at
    self.achieved_at ||= Time.current
  end
end

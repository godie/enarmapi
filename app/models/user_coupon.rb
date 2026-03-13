class UserCoupon < ApplicationRecord
  belongs_to :user
  belongs_to :coupon

  validates :user_id, uniqueness: { scope: :coupon_id, message: "ya ha usado este cupón" }

  scope :used, -> { where.not(used_at: nil) }
  scope :active, -> { where(used_at: nil) }
end

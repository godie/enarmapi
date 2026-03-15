class Coupon < ApplicationRecord
  has_many :user_coupons, dependent: :destroy
  has_many :users, through: :user_coupons

  validates :code, presence: true, uniqueness: true
  validates :coupon_type, presence: true
  validates :expiration_date, presence: true

  def expired?
    expiration_date < Time.current
  end
end

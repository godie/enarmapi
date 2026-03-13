class V2CouponsController < ApplicationController
  before_action :authenticate_user!

  def me
    active_coupons = Current.user.coupons.merge(UserCoupon.active)
    used_coupons = Current.user.coupons.merge(UserCoupon.used)

    render json: {
      active: active_coupons.map { |c| format_coupon(c, false) },
      used: used_coupons.map { |c| format_coupon(c, true) }
    }
  end

  private

  def format_coupon(coupon, used)
    {
      id: coupon.id,
      code: coupon.code,
      description: coupon.description,
      expiration_date: coupon.expiration_date,
      coupon_type: coupon.coupon_type,
      used: used,
      expired: coupon.expired?
    }
  end
end

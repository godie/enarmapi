require "test_helper"

class V2CouponsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:player_one)
    @coupon1 = Coupon.create!(code: "DESC10", coupon_type: "percentage", expiration_date: 1.day.from_now, description: "10% off")
    @coupon2 = Coupon.create!(code: "FREE", coupon_type: "fixed", expiration_date: 1.day.from_now, description: "Free")
    @user.user_coupons.create!(coupon: @coupon1)
    @user.user_coupons.create!(coupon: @coupon2, used_at: Time.current)
  end

  test "should get me coupons" do
    get "/v2/coupons/me", headers: player_auth_headers(@user)
    assert_response :success

    data = json_response
    assert_equal 1, data["active"].size
    assert_equal 1, data["used"].size
    assert_equal "DESC10", data["active"].first["code"]
    assert_equal "FREE", data["used"].first["code"]
  end

  test "should fail if not authenticated" do
    get "/v2/coupons/me"
    assert_response :unauthorized
  end
end

class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code
      t.datetime :expiration_date
      t.text :description
      t.string :coupon_type

      t.timestamps
    end
  end
end

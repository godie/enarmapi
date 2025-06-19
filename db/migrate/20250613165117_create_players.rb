class CreatePlayers < ActiveRecord::Migration[7.2]
  def change
    create_table :players do |t|
      t.string :email
      t.string :facebook_id
      t.string :name

      t.timestamps
    end
  end
end

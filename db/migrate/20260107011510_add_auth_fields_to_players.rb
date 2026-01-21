class AddAuthFieldsToPlayers < ActiveRecord::Migration[7.2]
  def change
    add_column :players, :password_digest, :string
    add_column :players, :google_id, :string
    add_column :players, :username, :string

    add_index :players, :email, unique: true
    add_index :players, :username, unique: true
    add_index :players, :google_id, unique: true
    add_index :players, :facebook_id, unique: true
  end
end

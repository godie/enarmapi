class AddDescriptionToCategory < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :description, :string
  end
end

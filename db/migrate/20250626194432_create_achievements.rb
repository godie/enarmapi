class CreateAchievements < ActiveRecord::Migration[7.2]
  def change
    create_table :achievements do |t|
      t.string :name
      t.text :description
      t.jsonb :criteria
      t.string :icon_url
      t.integer :points

      t.timestamps
    end
  end
end

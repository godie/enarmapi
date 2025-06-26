class CreatePlayerAchievements < ActiveRecord::Migration[7.2]
  def change
    create_table :player_achievements do |t|
      t.references :player, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true
      t.datetime :achieved_at
      t.jsonb :progress

      t.timestamps
    end
  end
end

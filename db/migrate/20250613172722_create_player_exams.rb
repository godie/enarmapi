class CreatePlayerExams < ActiveRecord::Migration[7.2]
  def change
    create_table :player_exams do |t|
      t.references :player, null: false, foreign_key: true
      t.references :exam, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :score
      t.string :status # 'in_progress', 'completed', 'abandoned'
      t.timestamps
    end
  end
end

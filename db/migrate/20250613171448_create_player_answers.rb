class CreatePlayerAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :player_answers do |t|
      t.references :player, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :answer, null: false, foreign_key: true
      t.boolean :is_correct
      t.integer :time_taken
      t.string :mode, default: 'practice' # 'practice', 'quick_quiz', etc.

      t.timestamps
    end

    add_index :player_answers, [ :player_id, :question_id, :created_at ]
  end
end

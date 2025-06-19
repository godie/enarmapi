class CreatePlayerExamAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :player_exam_answers do |t|
      t.references :player_exam, null: false, foreign_key: true
      t.references :exam_question, null: false, foreign_key: true
      t.references :answer, null: false, foreign_key: true
      t.boolean :is_correct
      t.integer :points_earned
      t.timestamps
    end
    add_index :player_exam_answers, [ :player_exam_id, :exam_question_id ],
              unique: true, name: 'index_player_exam_question_unique'
  end
end

class CreateExamQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :exam_questions do |t|
      t.references :exam, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :position # orden de la pregunta en el examen
      t.integer :points
      t.timestamps
    end
     add_index :exam_questions, [ :exam_id, :question_id ], unique: true
  end
end

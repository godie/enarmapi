class CreateExams < ActiveRecord::Migration[7.2]
  def change
    create_table :exams do |t|
      t.string :name
      t.text :description
      t.integer :time_limit # minutes
      t.integer :passing_score
      t.boolean :active, default: true
      t.timestamps
    end
  end
end

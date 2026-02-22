class CreateFlashcards < ActiveRecord::Migration[8.1]
  def change
    create_table :flashcards do |t|
      t.text :front
      t.text :back
      t.references :category, null: true, foreign_key: true
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
  end
end

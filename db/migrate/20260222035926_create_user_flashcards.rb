class CreateUserFlashcards < ActiveRecord::Migration[8.1]
  def change
    create_table :user_flashcards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :flashcard, null: false, foreign_key: true
      t.datetime :next_review
      t.integer :interval, default: 0
      t.float :ease_factor, default: 2.5
      t.integer :repetitions, default: 0
      t.string :status, default: 'new'

      t.timestamps
    end
    add_index :user_flashcards, [:user_id, :flashcard_id], unique: true
  end
end

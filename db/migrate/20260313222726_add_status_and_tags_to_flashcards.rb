class AddStatusAndTagsToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_column :flashcards, :status, :string
    add_column :flashcards, :tags, :string
  end
end

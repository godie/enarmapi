class CreateTopicsAndArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      t.string :title
      t.timestamps
    end

    create_table :articles do |t|
      t.string :title
      t.text :content
      t.references :topic, null: false, foreign_key: true
      t.timestamps
    end
  end
end

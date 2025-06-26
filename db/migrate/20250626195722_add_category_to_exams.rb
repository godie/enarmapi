class AddCategoryToExams < ActiveRecord::Migration[7.2]
  def change
    add_reference :exams, :category, null: false, foreign_key: true
  end
end

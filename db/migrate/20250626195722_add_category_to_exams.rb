class AddCategoryToExams < ActiveRecord::Migration[7.2]
  def change
    add_reference :exams, :category, null: true, foreign_key: true
    reversible do |dir|
      dir.up do
        category = Category.find_by(name: "General") || Category.create!(name: "General")
        Exam.where(category_id: nil).update_all(category_id: category.id)
      end
    end
    change_column_null :exams, :category_id, false
  end
end

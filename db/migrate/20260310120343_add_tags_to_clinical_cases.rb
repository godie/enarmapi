class AddTagsToClinicalCases < ActiveRecord::Migration[8.1]
  def change
    add_column :clinical_cases, :tags, :string
  end
end

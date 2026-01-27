class AddStatusToClinicalCases < ActiveRecord::Migration[7.2]
  def change
    add_column :clinical_cases, :status, :integer, default: 0
    add_index :clinical_cases, :status
  end
end

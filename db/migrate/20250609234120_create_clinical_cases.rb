class CreateClinicalCases < ActiveRecord::Migration[7.2]
  def change
    create_table :clinical_cases do |t|
      t.references :category, null: false, foreign_key: true
      t.text :description
      t.string :name

      t.timestamps
    end
  end
end

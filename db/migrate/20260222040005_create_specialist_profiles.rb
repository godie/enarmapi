class CreateSpecialistProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :specialist_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :specialty
      t.text :bio
      t.integer :enarm_score
      t.boolean :is_verified, default: false

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class AddUserIdToClinicalCases < ActiveRecord::Migration[8.0]
  def change
    add_reference :clinical_cases, :user, null: true, foreign_key: true, index: true
  end
end

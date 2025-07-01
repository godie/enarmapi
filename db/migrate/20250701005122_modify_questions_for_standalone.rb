class ModifyQuestionsForStandalone < ActiveRecord::Migration[7.2]
  def change
    # Make clinical_case_id nullable
    change_column_null :questions, :clinical_case_id, true

    # Add category_id to questions table
    # The `references` type automatically adds a foreign key and an index.
    # We want it to be nullable as well.
    add_reference :questions, :category, null: true, foreign_key: true

    # It's good practice to also ensure the foreign key to clinical_cases is there,
    # though it should have been created with the initial table.
    # If not, `add_foreign_key :questions, :clinical_cases` would be needed.
    # The index on clinical_case_id should also exist.

    # Note: The generator might have already added the category_id column and index
    # if `category_id_for_question:references` was fully processed.
    # This script assumes we are ensuring the state. If `add_reference` fails because
    # the column exists, it means the generator did its job for that part.
    # However, `change_column_null` is definitely needed.
  end
end

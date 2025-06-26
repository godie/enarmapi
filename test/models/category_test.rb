require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  context "associations" do
    should have_many(:clinical_cases).dependent(:destroy)
    should have_many(:questions).through(:clinical_cases)
  end

  context "validations" do
    # Assuming a category 'one' is loaded from fixtures for uniqueness tests
    # or create one if fixtures are not guaranteed for this specific test setup.
    setup do
      # Ensure a category exists to test uniqueness against.
      # Using find_or_create_by to avoid errors if 'categories(:one)' is already used
      # or if it doesn't perfectly match what's needed for a clean test.
      Category.find_or_create_by!(name: categories(:one).name) if Category.fixture_path_defined? && categories(:one).name
    end

    should validate_presence_of(:name)

    # Need to create a record before testing uniqueness
    subject { Category.new(name: "SubjectCategory") } # Changed from :one as it might conflict
    should validate_uniqueness_of(:name).case_insensitive
  end

  context "callbacks" do
    should "normalize name before saving by titleizing and stripping whitespace" do
      category = Category.new(name: "  leading and trailing spaces and uncapitalized title  ")
      category.save!
      assert_equal "Leading And Trailing Spaces And Uncapitalized Title", category.name
    end

    should "not alter name if it's already normalized" do
      normalized_name = "Already Normalized Name"
      category = Category.create!(name: normalized_name) # Use create! to ensure it's saved
      category.name = normalized_name # Simulate no change
      category.save! # Trigger callbacks again
      assert_equal normalized_name, category.name
    end

    should "handle nil name gracefully in callback (validation should prevent save)" do
      category = Category.new(name: nil)
      assert_not category.valid? # Presence validation should fail
      assert_nothing_raised do
        category.send(:normalize_name) # Manually trigger callback to check for errors
      end
      assert_nil category.name # Name should remain nil after callback if it was nil
    end

     should "handle blank name by setting it to nil then caught by presence validator" do
      category = Category.new(name: "   ") # Only spaces
      # The normalize_name method as written (name.strip.titleize) would make "   " into ""
      # Then presence validation would catch it.
      assert_not category.valid?
      assert_includes category.errors[:name], "can't be blank"
    end
  end

  context "scopes" do
    setup do
      # Clear existing categories to ensure a clean slate for scope tests, or ensure names are unique
      # Category.delete_all # Use if necessary, but be careful with fixture dependencies

      @cat_b = Category.create!(name: "Scope Test B")
      @cat_a = Category.create!(name: "Scope Test A") # Note: fixture :one might be "Cardiología"
      @cat_c = Category.create!(name: "Scope Test C")
      @cat_d_no_cases = Category.create!(name: "Scope Test D No Cases")


      @cc1_cat_a = ClinicalCase.create!(name: "CC1A", category: @cat_a, description: "Desc")
      @cc2_cat_a = ClinicalCase.create!(name: "CC2A", category: @cat_a, description: "Desc")
      @cc1_cat_b = ClinicalCase.create!(name: "CC1B", category: @cat_b, description: "Desc")

      Question.create!(text: "Q1", clinical_case: @cc1_cat_a)
      Question.create!(text: "Q2", clinical_case: @cc1_cat_b)
    end

    should "order alphabetically using 'alphabetical' scope" do
      # Querying all created categories for this test context
      expected_order = [@cat_a, @cat_b, @cat_c, @cat_d_no_cases].sort_by(&:name)
      actual_order = Category.where(id: [@cat_a.id, @cat_b.id, @cat_c.id, @cat_d_no_cases.id]).alphabetical.to_a
      assert_equal expected_order.map(&:name), actual_order.map(&:name)
    end

    should "return categories with clinical cases using 'with_clinical_cases' scope" do
      categories_with_cases = Category.with_clinical_cases.to_a
      assert_includes categories_with_cases, @cat_a
      assert_includes categories_with_cases, @cat_b
      assert_not_includes categories_with_cases, @cat_c # Had no cases in original setup
      assert_not_includes categories_with_cases, @cat_d_no_cases
    end

    should "return most used categories using 'most_used' scope" do
      # @cat_a has 2 cases
      # @cat_b has 1 case
      # @cat_c, @cat_d_no_cases have 0 cases

      most_used_limit_1 = Category.most_used(1)
      assert_equal [@cat_a], most_used_limit_1.to_a

      most_used_limit_2 = Category.most_used(2).to_a # Convert to array for easier comparison
      # Order can be tricky with COUNT aggregates if counts are equal. Assuming DB returns them ordered by count then by primary key or name.
      # For this test, @cat_a (2 cases) should come before @cat_b (1 case).
      assert_equal 2, most_used_limit_2.size
      assert_includes most_used_limit_2, @cat_a
      assert_includes most_used_limit_2, @cat_b
      assert_equal @cat_a, most_used_limit_2.first # @cat_a should be first
    end
  end

  context "instance methods" do
    setup do
      @category_with_cases = categories(:one) # From fixtures, e.g., "Cardiología"
      # Ensure it has associated cases and questions for the test
      @cc1 = ClinicalCase.find_or_create_by!(name: "Fixture Case 1 for Category One", category: @category_with_cases, description: "Desc")
      @cc2 = ClinicalCase.find_or_create_by!(name: "Fixture Case 2 for Category One", category: @category_with_cases, description: "Desc")
      Question.find_or_create_by!(text: "Q1 in CC1", clinical_case: @cc1)
      Question.find_or_create_by!(text: "Q2 in CC1", clinical_case: @cc1)
      Question.find_or_create_by!(text: "Q1 in CC2", clinical_case: @cc2)

      @empty_category = Category.create!(name: "Empty Category For Instance Methods")
    end

    should "return correct clinical_cases_count" do
      # Reload to ensure counts are fresh if cases were added/removed by other tests/setups
      @category_with_cases.reload
      assert_equal 2, @category_with_cases.clinical_cases_count
      assert_equal 0, @empty_category.clinical_cases_count
    end

    should "return correct total_questions_count" do
      @category_with_cases.reload
      assert_equal 3, @category_with_cases.total_questions_count
      assert_equal 0, @empty_category.total_questions_count
    end

    context "#as_json" do
      should "return standard json by default" do
        json_output = @category_with_cases.as_json
        assert_not_includes json_output, "clinical_cases_count"
        assert_not_includes json_output, "total_questions_count"
        assert_equal @category_with_cases.name, json_output["name"]
        assert_equal @category_with_cases.description, json_output["description"]
      end

      should "include stats when :include_stats is true" do
        # Ensure counts are accurate before as_json call
        @category_with_cases.reload
        expected_cases_count = @category_with_cases.clinical_cases.count
        expected_questions_count = @category_with_cases.questions.count

        json_output = @category_with_cases.as_json(include_stats: true)

        assert_includes json_output, "clinical_cases_count"
        assert_includes json_output, "total_questions_count"
        assert_equal expected_cases_count, json_output["clinical_cases_count"]
        assert_equal expected_questions_count, json_output["total_questions_count"]
      end
    end
  end

  test "should be valid with valid attributes" do
    category = Category.new(name: "Unique Category Name For Validity Test", description: "Optional description")
    assert category.valid?, category.errors.full_messages.join(", ")
  end

  test "description attribute can be nil" do
    category = Category.new(name: "Category Without Description Test")
    assert category.valid?
    assert category.save
    assert_nil category.reload.description
  end

  test "name must be unique (case-insensitive)" do
    existing_category_name = "Existing Name for Uniqueness"
    Category.create!(name: existing_category_name)

    category_same_case = Category.new(name: existing_category_name)
    assert_not category_same_case.valid?
    assert_includes category_same_case.errors[:name], "has already been taken"

    category_different_case = Category.new(name: existing_category_name.downcase)
    assert_not category_different_case.valid?
    assert_includes category_different_case.errors[:name], "has already been taken"
  end
end

require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  # Associations
  test "should have many clinical_cases and they should be dependent destroy" do
    category = Category.new
    assert_respond_to category, :clinical_cases

    # Test dependent destroy
    category_with_case = Category.create!(name: "Category for Destroy Test")
    clinical_case = ClinicalCase.create!(name: "Case in Category for Destroy", category: category_with_case, description: "Test")
    case_id = clinical_case.id

    assert_difference "ClinicalCase.count", -1 do
      category_with_case.destroy
    end
    assert_not ClinicalCase.exists?(case_id)
  end

  test "should have many questions through clinical_cases" do
    category = Category.new
    assert_respond_to category, :questions
  end

  # Validations
  test "should validate presence of name" do
    category = Category.new(description: "A category without a name")
    assert_not category.valid?, "Category should be invalid without a name"
    assert_includes category.errors[:name], "can't be blank"
  end

  test "should validate uniqueness of name (case-insensitive)" do
    existing_name = "Unique Category Name #{SecureRandom.hex(3)}"
    Category.create!(name: existing_name, description: "First category with this name")

    category_same_case = Category.new(name: existing_name)
    assert_not category_same_case.valid?, "Category name should be unique (same case)"
    assert_includes category_same_case.errors[:name], "has already been taken"

    category_different_case = Category.new(name: existing_name.downcase)
    assert_not category_different_case.valid?, "Category name should be unique (different case)"
    assert_includes category_different_case.errors[:name], "has already been taken"
  end

  # Callbacks
  test "normalize_name callback should titleize and strip whitespace from name before saving" do
    category = Category.new(name: "  a messy category name  ")
    category.save! # Trigger callbacks
    assert_equal "A Messy Category Name", category.name, "Name was not normalized correctly"
  end

  test "normalize_name callback should not alter an already normalized name" do
    normalized = "Already Good Name"
    category = Category.new(name: normalized)
    category.save!
    assert_equal normalized, category.name
  end

  test "normalize_name callback should handle blank name by making it empty string (presence validation will catch)" do
    category = Category.new(name: "   ") # Only spaces
    category.send(:normalize_name) # Manually trigger callback for inspection if needed
    assert_equal "", category.name # normalize_name turns "   " into ""
    assert_not category.valid? # Presence validation should then fail for ""
    assert_includes category.errors[:name], "can't be blank"
  end


  # Scopes
  setup do
    # Clear relevant tables or ensure unique names for scope tests
    # ClinicalCase.delete_all # If dependent: :destroy is not set or to be sure
    # Category.delete_all

    @cat_alpha = Category.create!(name: "Alpha Category")
    @cat_beta = Category.create!(name: "Beta Category")
    @cat_gamma = Category.create!(name: "Gamma Category No Cases") # No cases for this one initially

    @cc_alpha1 = ClinicalCase.create!(name: "CC Alpha 1", category: @cat_alpha, description: "Desc")
    @cc_alpha2 = ClinicalCase.create!(name: "CC Alpha 2", category: @cat_alpha, description: "Desc") # @cat_alpha has 2 cases
    @cc_beta1 = ClinicalCase.create!(name: "CC Beta 1", category: @cat_beta, description: "Desc")   # @cat_beta has 1 case

    Question.create!(text: "Q for CC Alpha 1", clinical_case: @cc_alpha1)
    Question.create!(text: "Q for CC Beta 1", clinical_case: @cc_beta1)
  end

  test "alphabetical scope should order categories by name" do
    # Fetching specific categories created in setup to avoid interference from fixtures or other tests
    ids_for_scope_test = [@cat_alpha.id, @cat_beta.id, @cat_gamma.id]
    categories_for_test = Category.where(id: ids_for_scope_test).alphabetical.to_a

    expected_order = [@cat_alpha, @cat_beta, @cat_gamma].sort_by(&:name)
    assert_equal expected_order.map(&:id), categories_for_test.map(&:id), "Categories are not in alphabetical order"
  end

  test "with_clinical_cases scope should return categories that have at least one clinical case" do
    categories_with_cases = Category.with_clinical_cases
    assert_includes categories_with_cases, @cat_alpha
    assert_includes categories_with_cases, @cat_beta
    assert_not_includes categories_with_cases, @cat_gamma # @cat_gamma has no clinical cases
  end

  test "most_used scope should return categories ordered by the number of clinical cases (descending)" do
    # @cat_alpha has 2 cases, @cat_beta has 1 case, @cat_gamma has 0 cases

    most_used_1 = Category.most_used(1).to_a
    assert_equal [@cat_alpha], most_used_1, "Most used (limit 1) should be @cat_alpha"

    most_used_2 = Category.most_used(2).to_a
    # Order should be @cat_alpha then @cat_beta
    assert_equal 2, most_used_2.size
    assert_equal @cat_alpha, most_used_2.first, "First in most_used (limit 2) should be @cat_alpha"
    assert_equal @cat_beta, most_used_2.second, "Second in most_used (limit 2) should be @cat_beta"

    most_used_all = Category.most_used(3).to_a # or more than total categories with cases
    assert_equal 2, most_used_all.select { |c| c.clinical_cases.any? }.count # Only those with cases should be effectively "used"
                                                                             # The scope counts clinical_cases.id, so 0-count categories might appear if not filtered out.
                                                                             # The current scope `left_joins(:clinical_cases).group("categories.id").order("COUNT(clinical_cases.id) DESC")`
                                                                             # will include categories with 0 cases if limit allows.
    assert_equal @cat_alpha, most_used_all.first
    assert_equal @cat_beta, most_used_all.second
    # @cat_gamma would be last if included, with a count of 0.
    # Depending on how COUNT(clinical_cases.id) and limit interact with categories having 0 cases.
    # Let's verify if @cat_gamma is there if limit is 3
    most_used_3 = Category.most_used(3).to_a
    if most_used_3.size == 3
        assert_includes most_used_3, @cat_gamma # If categories with 0 cases are included by the scope
        assert_equal @cat_gamma, most_used_3.third # And it should be last due to 0 count
    else # if scope implicitly filters out 0-count or DB handles it
        assert_equal 2, most_used_3.size # Then only @cat_alpha and @cat_beta
    end

  end

  # Instance Methods
  test "clinical_cases_count should return the number of associated clinical cases" do
    category = categories(:one) # From fixtures; assuming it has clinical_cases(:one) and potentially others
    # Let's use a freshly created category for precise count
    new_cat = Category.create!(name: "Count Test Cat")
    assert_equal 0, new_cat.clinical_cases_count

    ClinicalCase.create!(name: "CC1 for Count", category: new_cat, description: "d")
    ClinicalCase.create!(name: "CC2 for Count", category: new_cat, description: "d")
    new_cat.reload # Reload to ensure association is fresh
    assert_equal 2, new_cat.clinical_cases_count
  end

  test "total_questions_count should return the number of questions associated through clinical cases" do
    category = categories(:two) # From fixtures
     # Let's use a freshly created category for precise count
    new_cat_q = Category.create!(name: "Count Q Test Cat")
    assert_equal 0, new_cat_q.total_questions_count

    cc1 = ClinicalCase.create!(name: "CC1 for Q Count", category: new_cat_q, description: "d")
    cc2 = ClinicalCase.create!(name: "CC2 for Q Count", category: new_cat_q, description: "d")
    Question.create!(text: "Q1 CC1", clinical_case: cc1)
    Question.create!(text: "Q2 CC1", clinical_case: cc1)
    Question.create!(text: "Q1 CC2", clinical_case: cc2)
    new_cat_q.reload
    assert_equal 3, new_cat_q.total_questions_count
  end

  test "as_json should return standard JSON by default" do
    category = categories(:one) # Assuming this fixture exists
    json_output = category.as_json
    assert_kind_of Hash, json_output
    assert_includes json_output, "name"
    assert_includes json_output, "description" # if description is part of default as_json
    assert_not_includes json_output, "clinical_cases_count"
    assert_not_includes json_output, "total_questions_count"
  end

  test "as_json should include stats when :include_stats option is true" do
    # Use a category with known counts
    cat_for_json = Category.create!(name: "JSON Stats Test")
    cc_json = ClinicalCase.create!(name: "CC for JSON", category: cat_for_json, description: "d")
    Question.create!(text: "Q1 JSON", clinical_case: cc_json)
    Question.create!(text: "Q2 JSON", clinical_case: cc_json)
    cat_for_json.reload

    expected_cases_count = 1
    expected_questions_count = 2
    assert_equal expected_cases_count, cat_for_json.clinical_cases_count
    assert_equal expected_questions_count, cat_for_json.total_questions_count

    json_output = cat_for_json.as_json(include_stats: true)
    assert_includes json_output, "clinical_cases_count"
    assert_equal expected_cases_count, json_output["clinical_cases_count"]
    assert_includes json_output, "total_questions_count"
    assert_equal expected_questions_count, json_output["total_questions_count"]
  end

  # General model validity
  test "should be valid with all required attributes" do
    category = Category.new(name: "A Valid Category Name #{SecureRandom.hex(3)}", description: "Optional description here.")
    assert category.valid?, category.errors.full_messages.join(", ")
  end

  test "description attribute can be nil" do
    category = Category.new(name: "Category With No Description #{SecureRandom.hex(3)}")
    assert category.valid?, "Category should be valid even without a description"
    assert category.save
    assert_nil category.reload.description
  end
end

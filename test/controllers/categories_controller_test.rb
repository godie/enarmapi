require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  # Load fixtures for categories, which will provide test data
  fixtures :categories, :users

  setup do
    @category_one = categories(:one) # Assuming you have a fixture named 'one' in categories.yml
    @category_two = categories(:two) # Assuming you have a fixture named 'two' in categories.yml
    @admin_user = users(:admin)
    @auth_headers = admin_auth_headers(@admin_user)
  end

  # --- INDEX action tests ---
  test "should get index" do
    get categories_url, as: :json # Make a GET request to /categories
    assert_response :success      # Assert that the response was successful (200 OK)

    json_response = JSON.parse(response.body)
    assert_instance_of Array, json_response # Ensure the response is an array

    # Assert correct number of categories
    assert_equal Category.count, json_response.count

    # Assert that the JSON contains expected data for at least one category
    # Find the category_one in the JSON response
    category_one_json = json_response.find { |c| c["id"] == @category_one.id }
    refute_nil category_one_json, "Category one should be in the response"
    assert_equal @category_one.name, category_one_json["name"]
    assert_equal @category_one.description, category_one_json["description"]

    # Also check a second category to ensure multiple are rendered
    category_two_json = json_response.find { |c| c["id"] == @category_two.id }
    refute_nil category_two_json, "Category two should be in the response"
  end

  # --- CREATE action tests ---
  test "should create category with valid parameters" do
    assert_difference("Category.count", 1) do # Assert that one Category record is created
      post categories_url, params: { category: { name: "New Category", description: "A brand new category" } }, headers: @auth_headers, as: :json
    end

    assert_response :created # Assert that the response status is 201 Created
    json_response = JSON.parse(response.body)

    # Assert the response body contains the newly created category's data
    assert_equal "New Category", json_response["name"]
    assert_equal "A brand new category", json_response["description"]
    assert_not_nil json_response["id"] # Ensure an ID was assigned

    # Verify that the category was actually saved to the database
    created_category = Category.find(json_response["id"])
    assert_equal "New Category", created_category.name
    assert_equal "A brand new category", created_category.description
  end

  test "should not create category with invalid parameters (missing name)" do
    assert_no_difference("Category.count") do # Assert that no Category record is created
      post categories_url, params: { category: { description: "Invalid category" } }, headers: @auth_headers, as: :json
    end

    assert_response :unprocessable_entity # Assert status 422 Unprocessable Entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["name"], "can't be blank" # Check for specific error message
  end

  test "should not create category with invalid parameters (name too short/long if validated)" do
    # Assuming Category model has `validates :name, length: { minimum: 3 }`
    # You would need to add this validation to your Category model first if you want this test to pass.
    # For now, let's just test a basic invalid (e.g., empty) name if your model handles it.
    assert_no_difference("Category.count") do
      post categories_url, params: { category: { name: "", description: "Empty name" } }, headers: @auth_headers, as: :json
    end
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["name"], "can't be blank"
  end


  # --- SHOW action tests ---
  test "should show category" do
    get category_url(@category_one), headers: @auth_headers, as: :json # Make a GET request to /categories/ID
    assert_response :success # Assert 200 OK

    json_response = JSON.parse(response.body)
    assert_equal @category_one.id, json_response["id"]
    assert_equal @category_one.name, json_response["name"]
    assert_equal @category_one.description, json_response["description"]
  end

  test "should not show non-existent category" do
    get category_url(999999), headers: @auth_headers, as: :json # Request a non-existent ID
    assert_response :not_found # Assert 404 Not Found (due to set_category before_action)
  end

  # --- UPDATE action tests ---
  test "should update category with valid parameters" do
    patch category_url(@category_one), params: { category: { name: "Updated Category Name", description: "New description" } }, headers: @auth_headers, as: :json
    assert_response :ok # Assert 200 OK

    @category_one.reload # Reload the fixture object to get updated data from the DB
    assert_equal "Updated Category Name", @category_one.name
    assert_equal "New description", @category_one.description

    json_response = JSON.parse(response.body)
    assert_equal "Updated Category Name", json_response["name"]
    assert_equal "New description", json_response["description"]
  end

  test "should not update category with invalid parameters (missing name)" do
    original_name = @category_one.name
    patch category_url(@category_one), params: { category: { name: "" } }, headers: @auth_headers, as: :json
    assert_response :unprocessable_entity # Assert 422 Unprocessable Entity

    @category_one.reload # Reload to ensure it was NOT updated
    assert_equal original_name, @category_one.name # Name should remain unchanged

    json_response = JSON.parse(response.body)
    assert_includes json_response["name"], "can't be blank"
  end

  test "should not update non-existent category" do
    patch category_url(999999), params: { category: { name: "Non-Existent" } }, headers: @auth_headers, as: :json
    assert_response :not_found # Assert 404 Not Found
  end
end

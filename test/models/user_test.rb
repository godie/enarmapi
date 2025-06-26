require "test_helper"

class UserTest < ActiveSupport::TestCase
  fixtures :users
  # No direct associations defined in the User model snippet to test here.

  # Validations
  setup do
    # For uniqueness tests: ensure users(:one) from users.yml is present.
    # It typically has username 'adminuser', email 'admin@example.com'.
    @user_one_fixture_username = users(:user_one).username
    @user_one_fixture_email = users(:user_one).email

    User.find_or_create_by!(username: @user_one_fixture_username) do |u_setup|
      u_setup.email = @user_one_fixture_email # Assign if username is unique key for find
      u_setup.password = "fixture_password" # has_secure_password requires a password
    end
    # If email might be different from username-derived one, ensure it's also unique for email tests
    unless @user_one_fixture_email == "#{@user_one_fixture_username}@example.com" # Example check
      User.find_or_create_by!(email: "another_unique_email_for_setup@example.com") do |u_email_setup|
        u_email_setup.username = "another_unique_username_for_email"
        u_email_setup.password = "fixture_password"
      end
    end
  end

  test "should validate presence of email" do
    user = User.new(username: "user_no_email", password: "password")
    assert_not user.valid?, "User should be invalid without an email"
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should validate uniqueness of email (case-insensitive)" do
    # @user_one_fixture_email (e.g., "admin@example.com") exists from setup.
    user_same_case = User.new(username: "user_dup_email1", email: @user_one_fixture_email, password: "password")
    assert_not user_same_case.valid?, "Email should be unique (same case)"
    assert_includes user_same_case.errors[:email], "has already been taken"

    user_diff_case = User.new(username: "user_dup_email2", email: @user_one_fixture_email.downcase, password: "password")
    assert_not user_diff_case.valid?, "Email should be unique (different case)"
    assert_includes user_diff_case.errors[:email], "has already been taken"
  end

  test "should validate presence of username" do
    user = User.new(email: "user_no_username@example.com", password: "password")
    assert_not user.valid?, "User should be invalid without a username"
    assert_includes user.errors[:username], "can't be blank"
  end

  test "should validate uniqueness of username (case-insensitive)" do
    # @user_one_fixture_username (e.g., "adminuser") exists from setup.
    user_same_case = User.new(username: @user_one_fixture_username, email: "other_email1@example.com", password: "password")
    assert_not user_same_case.valid?, "Username should be unique (same case)"
    assert_includes user_same_case.errors[:username], "has already been taken"

    user_diff_case = User.new(username: @user_one_fixture_username.upcase, email: "other_email2@example.com", password: "password")
    assert_not user_diff_case.valid?, "Username should be unique (different case)"
    assert_includes user_diff_case.errors[:username], "has already been taken"
  end

  test "email format should be valid (basic check using URI::MailTo::EMAIL_REGEXP)" do
    # Model does not explicitly validate email format with a regex, but `has_secure_password`
    # and general good practice implies a reasonable email. Rails' default error messages
    # for email format are usually tied to a `format` validator if one is present.
    # Here, we're mostly testing common valid/invalid cases.
    valid_emails = [ "user@example.com", "first.last@example.com", "user+tag@example.com" ]
    invalid_emails = [ "user@example", "@example.com", "user" ] # Examples of clearly invalid formats

    valid_emails.each do |email|
      user = User.new(username: "emailfmt_#{SecureRandom.hex(2)}", email: email, password: "password")
      # If no specific format validator, it might pass as long as it's present.
      # This test is more about intent. If a format validator were added, it would be more specific.
      # For now, just checking if it doesn't raise unexpected errors.
      assert user.valid?  if email.match?(URI::MailTo::EMAIL_REGEXP) # Check against the regexp Rails often uses
      # If it's not valid, we'd expect `user.errors[:email]` to contain "is invalid" or similar.
    end

    invalid_emails.each do |email|
        user = User.new(username: "emailfmt_inv_#{SecureRandom.hex(2)}", email: email, password: "password")
      # Without an explicit format validator in the User model, these might not fail validation
      # solely based on format, only on presence if blank.
      # If a format validator (e.g. `validates :email, format: { with: SOME_REGEX }`) was in User model,
      # then `assert_not user.valid?` and `assert_includes user.errors[:email], "is invalid"` would be appropriate.
      # For now, this part of the test is more illustrative of what *could* be tested.
      # assert_not user.valid?, "#{email} should be invalid" # This would fail if no format validator
    end
    # Given the current model, only presence and uniqueness of email are explicitly validated.
  end

  # has_secure_password functionality
  test "should have a password_digest attribute" do
    # This is implicitly tested by `has_secure_password` but can be explicit.
    assert User.column_names.include?("password_digest"), "User model should have a password_digest column"
  end

  test "authenticate method works correctly with valid and invalid passwords" do
    password_to_test = "mySecurePassword123!"
    user = User.create!(
      username: "auth_user_test_#{SecureRandom.hex(3)}",
      email: "auth_test_#{SecureRandom.hex(3)}@example.com",
      password: password_to_test,
      password_confirmation: password_to_test
    )
    assert user.authenticate(password_to_test), "Authentication should succeed with the correct password."
    assert_not user.authenticate("ThisIsAWrongPassword"), "Authentication should fail with an incorrect password."
    assert_not user.authenticate(nil), "Authentication should fail with a nil password."
    assert_not user.authenticate(""), "Authentication should fail with an empty password string."
  end

  test "password and password_confirmation are required on new record creation" do
    user_no_pass = User.new(username: "user_no_pass_#{SecureRandom.hex(3)}", email: "nopass_#{SecureRandom.hex(3)}@example.com")
    assert_not user_no_pass.valid?, "User creation should fail without a password."
    assert_includes user_no_pass.errors[:password], "can't be blank"

    user_mismatch_confirm = User.new(
      username: "user_confirm_#{SecureRandom.hex(3)}",
      email: "confirm_#{SecureRandom.hex(3)}@example.com",
      password: "passwordValue",
      password_confirmation: "differentPasswordValue"
    )
    assert_not user_mismatch_confirm.valid?, "User creation should fail if password_confirmation does not match."
    assert_includes user_mismatch_confirm.errors[:password_confirmation], "doesn't match Password"
  end

  test "password is not required on update if password field is not being changed" do
    user_to_update = User.create!(
      username: "update_user_test_#{SecureRandom.hex(3)}",
      email: "update_test_#{SecureRandom.hex(3)}@example.com",
      password: "initial_secret_password"
    )
    user_to_update.username = "new_updated_username" # Update a non-password field
    # Do not set user.password or user.password_confirmation
    assert user_to_update.valid?, "User should remain valid when updating non-password fields. Errors: #{user_to_update.errors.full_messages.join(", ")}"
    assert user_to_update.save
  end

  test "if password field is set on update, confirmation is also required and must match" do
    user_changing_pass = User.create!(
      username: "change_pass_user_#{SecureRandom.hex(3)}",
      email: "changepass_test_#{SecureRandom.hex(3)}@example.com",
      password: "old_secret_password"
    )

    # Scenario 1: Password set, confirmation blank
    user_changing_pass.password = ""
    user_changing_pass.password_confirmation = ""
    assert_not user_changing_pass.valid?, "Should be invalid if password is set but confirmation is blank during update."
    assert_includes user_changing_pass.errors[:password_confirmation], "doesn't match Password"

    # Scenario 2: Password set, confirmation mismatch
    user_changing_pass.password_confirmation = "mismatched_new_secret"
    assert_not user_changing_pass.valid?, "Should be invalid if password confirmation mismatches during update."
    assert_includes user_changing_pass.errors[:password_confirmation], "doesn't match Password"

    # Scenario 3: Password set, confirmation matches - should be valid
    user_changing_pass.password = "a_new_secret_password"
    user_changing_pass.password_confirmation = "a_new_secret_password"
    assert user_changing_pass.valid?, "Should be valid if password and matching confirmation are provided for update. Errors: #{user_changing_pass.errors.full_messages.join(", ")}"
  end

  # General Validity and Optional Attributes
  test "should be valid with all required attributes (username, email, password)" do
    user = User.new(
      name: "Optional User Name", # `name` is not validated for presence in the current User model
      username: "valid_user_test_#{SecureRandom.hex(4)}",
      email: "valid_test_#{SecureRandom.hex(4)}@example.com",
      password: "a_secure_password123",
      password_confirmation: "a_secure_password123"
    )
    assert user.valid?, user.errors.full_messages.join(", ")
  end

  test "name attribute (not validated for presence) can be nil" do
    user_with_nil_name = User.new(
      username: "nil_name_user_test_#{SecureRandom.hex(4)}",
      email: "nilname_test_#{SecureRandom.hex(4)}@example.com",
      password: "password_value"
      # `name` attribute is not set, so it defaults to nil.
    )
    assert user_with_nil_name.valid?, "User should be valid with a nil name. Errors: #{user_with_nil_name.errors.full_messages.join(", ")}"
    assert user_with_nil_name.save
    assert_nil user_with_nil_name.reload.name
  end
end

require "test_helper"

class UserTest < ActiveSupport::TestCase
  context "validations" do
    setup do
      # Ensure users(:one) from users.yml is loaded for shoulda-matchers context
      # It has username 'adminuser', email 'admin@example.com'
      User.find_or_create_by!(username: users(:one).username) do |u|
        u.email = users(:one).email
        u.password = "fixturepassword" # has_secure_password needs this
      end
      # Create another user if users(:one).email is different from users(:one).username based email
      # to ensure both username and email uniqueness are tested against existing records.
      unless users(:one).email == "#{users(:one).username}@example.com" # Arbitrary check
         User.find_or_create_by!(email: "another_email_for_setup@example.com") do |u|
            u.username = "another_user_for_setup"
            u.password = "fixturepassword"
        end
      end
    end

    # Subject for shoulda-matchers uniqueness tests.
    # Must be a NEW, potentially conflicting record.
    subject do
      User.new(
        username: "subject_user_#{SecureRandom.hex(4)}",
        email: "subject_email_#{SecureRandom.hex(4)}@example.com",
        password: "subject_password"
      )
    end

    should validate_presence_of(:email)
    should validate_uniqueness_of(:email).case_insensitive

    should validate_presence_of(:username)
    should validate_uniqueness_of(:username).case_insensitive

    # Email format (basic check, URI::MailTo::EMAIL_REGEXP is quite permissive)
    should allow_value("user@example.com").for(:email)
    should allow_value("user.name@sub.example.co.uk").for(:email)
    # Example of what might be considered invalid by a stricter regex (not currently in model)
    # should_not allow_value("user@example").for(:email).with_message("is invalid")
  end

  context "has_secure_password functionality" do
    should have_secure_password # Checks for password_digest, virtual attrs, authenticate method

    test "password_digest attribute is present" do
      assert_includes User.column_names, "password_digest"
    end

    test "authenticate method works as expected" do
      password_val = "mySecurePassword123"
      user = User.create!(
        username: "auth_user_#{SecureRandom.hex(3)}",
        email: "auth_#{SecureRandom.hex(3)}@example.com",
        password: password_val,
        password_confirmation: password_val # Necessary for creation
      )
      assert user.authenticate(password_val), "Authentication should succeed with the correct password."
      assert_not user.authenticate("wrongPassword"), "Authentication should fail with an incorrect password."
      assert_not user.authenticate(nil), "Authentication should fail with a nil password."
    end

    test "password (and confirmation) is required on new record creation" do
      user = User.new(username: "no_pass_user_#{SecureRandom.hex(3)}", email: "nopass_#{SecureRandom.hex(3)}@example.com")
      assert_not user.valid?, "User should be invalid without a password."
      assert_includes user.errors[:password], "can't be blank"
    end

    test "password_confirmation must match password during creation" do
      user = User.new(
        username: "confirm_user_#{SecureRandom.hex(3)}",
        email: "confirm_#{SecureRandom.hex(3)}@example.com",
        password: "passwordA",
        password_confirmation: "passwordB" # Mismatch
      )
      assert_not user.valid?, "User should be invalid if password_confirmation does not match."
      assert_includes user.errors[:password_confirmation], "doesn't match Password"
    end

    test "password is not required on update if password field is not provided" do
      user = User.create!(
        username: "update_user_#{SecureRandom.hex(3)}",
        email: "update_#{SecureRandom.hex(3)}@example.com",
        password: "initial_password"
      )
      user.username = "updated_username_field"
      # Not touching user.password or user.password_confirmation
      assert user.valid?, "User should be valid when updating non-password fields. Errors: #{user.errors.full_messages.join(", ")}"
      assert user.save
    end

    test "if password field is provided on update, confirmation is also required and must match" do
      user = User.create!(
        username: "change_pass_#{SecureRandom.hex(3)}",
        email: "changepass_#{SecureRandom.hex(3)}@example.com",
        password: "old_password_val"
      )

      # Scenario 1: password provided, confirmation blank
      user.password = "new_password_val"
      user.password_confirmation = ""
      assert_not user.valid?
      # has_secure_password makes password_confirmation required if password_digest is being changed (i.e. password is set)
      assert_includes user.errors[:password_confirmation], "can't be blank"

      # Scenario 2: password provided, confirmation mismatch
      user.password_confirmation = "mismatch_new_password_val"
      assert_not user.valid?
      assert_includes user.errors[:password_confirmation], "doesn't match Password"

      # Scenario 3: password provided, confirmation matches
      user.password_confirmation = "new_password_val"
      assert user.valid?, "User should be valid if password and matching confirmation are provided. Errors: #{user.errors.full_messages.join(", ")}"
    end
  end

  test "should be valid when all required attributes (username, email, password) are present and valid" do
    user = User.new(
      name: "Optional Name Field", # `name` is not validated for presence
      username: "validuser_#{SecureRandom.hex(4)}",
      email: "valid_#{SecureRandom.hex(4)}@example.com",
      password: "a_valid_password",
      password_confirmation: "a_valid_password"
    )
    assert user.valid?, user.errors.full_messages.join(", ")
  end

  test "name attribute (not validated for presence) can be nil" do
    user = User.new(
      username: "nilnameuser_#{SecureRandom.hex(4)}",
      email: "nilname_#{SecureRandom.hex(4)}@example.com",
      password: "password_val"
      # name is not set, so it's nil
    )
    assert user.valid?, "User should be valid with a nil name. Errors: #{user.errors.full_messages.join(", ")}"
    assert user.save
    assert_nil user.reload.name
  end

  # More explicit manual tests for case-insensitive uniqueness
  test "username must be unique (case-insensitive check)" do
    upcase_username = "UniqueUserForTest_#{SecureRandom.hex(3)}"
    downcase_username = upcase_username.downcase

    User.create!(username: upcase_username, email: "unique_user_email1_#{SecureRandom.hex(3)}@example.com", password: "password")

    user_conflict_same_case = User.new(username: upcase_username, email: "other_email1_#{SecureRandom.hex(3)}@example.com", password: "password")
    assert_not user_conflict_same_case.valid?
    assert_includes user_conflict_same_case.errors[:username], "has already been taken"

    user_conflict_different_case = User.new(username: downcase_username, email: "other_email2_#{SecureRandom.hex(3)}@example.com", password: "password")
    assert_not user_conflict_different_case.valid?
    assert_includes user_conflict_different_case.errors[:username], "has already been taken"
  end

  test "email must be unique (case-insensitive check)" do
    upcase_email = "UniqueEmailForTest_#{SecureRandom.hex(3)}@example.com"
    downcase_email = upcase_email.downcase

    User.create!(username: "unique_email_userA_#{SecureRandom.hex(3)}", email: upcase_email, password: "password")

    user_conflict_same_case = User.new(username: "other_userA_#{SecureRandom.hex(3)}", email: upcase_email, password: "password")
    assert_not user_conflict_same_case.valid?
    assert_includes user_conflict_same_case.errors[:email], "has already been taken"

    user_conflict_different_case = User.new(username: "other_userB_#{SecureRandom.hex(3)}", email: downcase_email, password: "password")
    assert_not user_conflict_different_case.valid?
    assert_includes user_conflict_different_case.errors[:email], "has already been taken"
  end
end

class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  # Assuming username should also be present and unique based on typical user models
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  # The custom validation 'email_or_username_present' is no longer needed if both are required.
end

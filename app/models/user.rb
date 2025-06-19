class User < ApplicationRecord
  has_secure_password
  validates :email,    uniqueness: { case_sensitive: false }, allow_blank: true
  validates :username, uniqueness: { case_sensitive: false }, allow_blank: true
  validate :email_or_username_present

  private
  def email_or_username_present
    if email.blank? && username.blank?
      errors.add(:base, "Debe proporcionar al menos un correo electrónico o un username")
    end
  end
end

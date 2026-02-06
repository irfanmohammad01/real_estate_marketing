class SuperUser < ApplicationRecord
  VALID_PASSWORD_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}\z/

  has_secure_password
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, format: { with: VALID_PASSWORD_REGEX, message: "must include uppercase, lowercase, number, and special character" }, if: -> { password.present? }
end

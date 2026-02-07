class User < ApplicationRecord
  VALID_PASSWORD_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}\z/
  VALID_EMAIL_REGEX = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
  belongs_to :organization
  belongs_to :role
  has_secure_password

  validates :email, presence: true, uniqueness: { scope: :organization_id }, format: {with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }, if: -> { email.present? }
  validates :full_name, presence: true, length: { maximum: 150 }
  validates :phone, length: { is: 10 }, if: -> { phone.present? }
  validates :status, presence: true
  validates :password, presence: true, format: { with: VALID_PASSWORD_REGEX, message: "must include uppercase, lowercase, number, and special character" }, if: -> { password.present? }
end

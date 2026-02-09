class SuperUser < ApplicationRecord
  VALID_PASSWORD_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}\z/

  # Callbacks
  before_create :generate_jti

  has_secure_password
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { maximum: 100 }, format: { with: VALID_PASSWORD_REGEX, message: "must include uppercase, lowercase, number, and special character" }, if: -> { password.present? }

  # Generate new JTI for token revocation
  def rotate_jti!
    update!(jti: SecureRandom.uuid)
  end

  private

  # Automatically generate JTI on user creation
  def generate_jti
    self.jti ||= SecureRandom.uuid
  end
end

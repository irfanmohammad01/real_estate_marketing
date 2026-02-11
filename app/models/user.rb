class User < ApplicationRecord
  acts_as_paranoid
  VALID_PASSWORD_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}\z/
  VALID_EMAIL_REGEX = /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
  belongs_to :organization
  belongs_to :role
  has_secure_password

  # Callbacks
  before_create :generate_jti

  def org_admin?
    role.name == Role::ROLES[:org_admin]
  end

  def org_user?
    role.name == Role::ROLES[:org_user]
  end


  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }, if: -> { email.present? }
  validates :full_name, presence: true, length: { maximum: 150 }
  validates :phone, presence: true, length: { is: 10 }
  validates :status, presence: true
  validates :password, presence: true, format: { with: VALID_PASSWORD_REGEX, message: "must include uppercase, lowercase, number, and special character" }, if: -> { password.present? }

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

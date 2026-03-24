class Contact < ApplicationRecord
  belongs_to :organization
  has_many :preferences, dependent: :destroy

  before_validation :downcase_email

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, length: { is: 10 }
  validates :organization_id, presence: true

  private
  def downcase_email
    self.email = email.downcase if email.present?
  end
end

class Contact < ApplicationRecord
  belongs_to :organization
  has_many :preferences, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: { scope: :organization_id }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, length: { is: 10 }
  validates :organization_id, presence: true
end

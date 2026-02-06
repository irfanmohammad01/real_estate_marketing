class Contact < ApplicationRecord
  belongs_to :organization
  has_many :preferences, dependent: :destroy

  validates :first_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end

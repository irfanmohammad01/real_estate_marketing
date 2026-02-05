class EmailTemplate < ApplicationRecord
  belongs_to :organization
  belongs_to :email_type

  validates :from_email, presence: true
  validates :from_email, format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :reply_to, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end

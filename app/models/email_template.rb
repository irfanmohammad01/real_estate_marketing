class EmailTemplate < ApplicationRecord
  belongs_to :organization
  belongs_to :email_type

  validates :from_email, presence: true
  validates :from_email, format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :reply_to, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  validates :name, presence: true
  validates :subject, presence: true
  validates :preheader, presence: true
  validates :from_name, presence: true
  validates :from_email, presence: true
  validates :reply_to, presence: true
  validates :html_body, presence: true
  validates :text_body, presence: true
end

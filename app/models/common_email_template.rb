class CommonEmailTemplate < ApplicationRecord

  belongs_to :email_type

  validates :email_type_id, presence: true
  validates :from_name, presence: true, length: { maximum: 150 }
  validates :from_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :html_body, presence: true

  validates :name, length: { maximum: 150 }, allow_nil: true
  validates :subject, length: { maximum: 255 }, allow_nil: true
  validates :preheader, length: { maximum: 255 }, allow_nil: true
  validates :reply_to, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
end

class EmailTemplate < ApplicationRecord
  belongs_to :organization
  belongs_to :email_type

  validates :name, presence: true, uniqueness: { scope: :organization_id }, length: { maximum: 150 }
  validates :subject, presence: true, length: { maximum: 255 }
  validates :preheader, presence: true, length: { maximum: 255 }
  validates :from_name, presence: true, length: { maximum: 150 }
  validates :from_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :reply_to, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :html_body, presence: true
  validates :text_body, presence: true
end

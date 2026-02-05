class EmailType < ApplicationRecord
  has_many :email_templates, dependent: :destroy 
  validates :key, presence: true, uniqueness: true
end

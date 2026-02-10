class Organization < ApplicationRecord
  acts_as_paranoid
  has_many :users
  has_many :roles, through: :users

  scope :user_accessible, -> { where(is_system: false) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 150 }
  validates :description, presence: true, length: { maximum: 500 }
end

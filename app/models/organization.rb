class Organization < ApplicationRecord
  acts_as_paranoid

  validates :name, presence: true, uniqueness: true, length: { maximum: 150 }
end

class Role < ApplicationRecord
  has_many :users
  validates :name, presence: true, uniqueness: true, length: { maximum: 150 }
end

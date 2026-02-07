class PowerBackupType < ApplicationRecord
  has_many :preferences
  validates :name, presence: true, length: { maximum: 150 }
end

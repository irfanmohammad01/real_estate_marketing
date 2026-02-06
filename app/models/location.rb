class Location < ApplicationRecord
  has_many :preferences
  validates :city, presence: true
end

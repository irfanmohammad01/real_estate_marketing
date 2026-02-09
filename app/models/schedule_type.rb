class ScheduleType < ApplicationRecord
  ONE_TIME = "one-time".freeze
  RECURRING = "recurring".freeze

  has_many :campaigns, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :name, inclusion: { in: [ ONE_TIME, RECURRING ], message: "%{value} is not a valid schedule type" }
end

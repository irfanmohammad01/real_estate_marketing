class ScheduleType < ApplicationRecord

  SCHEDULE_TYPES = {
    ONE_TIME: "one-time",
    RECURRING: "recurring"
  }.freeze

  has_many :campaigns, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :name, inclusion: { in: SCHEDULE_TYPES.values, message: "%{value} is not a valid schedule type" }
end

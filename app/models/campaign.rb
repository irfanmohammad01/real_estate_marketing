class Campaign < ApplicationRecord
  STATUS_SCHEDULED = "scheduled".freeze
  STATUS_RUNNING = "running".freeze
  STATUS_COMPLETED = "completed".freeze
  STATUS_FAILED = "failed".freeze
  STATUS_PAUSED = "paused".freeze
  STATUS_CANCELLED = "cancelled".freeze

  VALID_STATUSES = [
    STATUS_SCHEDULED,
    STATUS_RUNNING,
    STATUS_COMPLETED,
    STATUS_FAILED,
    STATUS_PAUSED,
    STATUS_CANCELLED
  ].freeze

  belongs_to :organization
  belongs_to :email_template
  belongs_to :schedule_type

  has_many :campaign_audiences, dependent: :destroy
  has_many :audiences, through: :campaign_audiences
  # has_many :campaign_sends, dependent: :destroy

  validates :organization_id, presence: true
  validates :email_template_id, presence: true
  validates :schedule_type_id, presence: true
  validates :name, presence: true, uniqueness: { scope: :organization_id }, length: { maximum: 150 }
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }

  # validate :scheduled_at_required_for_one_time
  # validate :cron_expression_required_for_recurring
  # validate :end_date_after_scheduled_at
  # validate :validate_cron_expression_format

  # Callbacks
  # before_validation :set_default_status, on: :create

  # Scopes
  scope :scheduled, -> { where(status: STATUS_SCHEDULED) }
  scope :running, -> { where(status: STATUS_RUNNING) }
  scope :completed, -> { where(status: STATUS_COMPLETED) }
  scope :failed, -> { where(status: STATUS_FAILED) }
  scope :paused, -> { where(status: STATUS_PAUSED) }
  scope :cancelled, -> { where(status: STATUS_CANCELLED) }
  scope :active, -> { where(status: [ STATUS_SCHEDULED, STATUS_RUNNING, STATUS_PAUSED ]) }

  # Instance methods
  def one_time?
    schedule_type&.name == ScheduleType::SCHEDULE_TYPES[:ONE_TIME]
  end

  def recurring?
    schedule_type&.name == ScheduleType::SCHEDULE_TYPES[:RECURRING]
  end

  def can_be_edited?
    false # No editing allowed per requirements
  end

  def can_be_paused?
    [ STATUS_SCHEDULED, STATUS_RUNNING ].include?(status)
  end

  def can_be_resumed?
    status == STATUS_PAUSED
  end

  def can_be_cancelled?
    ![ STATUS_COMPLETED, STATUS_CANCELLED ].include?(status)
  end

  def pause!
    raise "Cannot pause campaign in #{status} status" unless can_be_paused?
    update!(status: STATUS_PAUSED)
  end

  def resume!
    raise "Cannot resume campaign in #{status} status" unless can_be_resumed?
    update!(status: STATUS_SCHEDULED)
  end

  def cancel!
    raise "Cannot cancel campaign in #{status} status" unless can_be_cancelled?
    update!(status: STATUS_CANCELLED)
  end

  def mark_as_running!
    update!(status: STATUS_RUNNING)
  end

  def mark_as_completed!
    update!(status: STATUS_COMPLETED)
  end

  def mark_as_failed!
    update!(status: STATUS_FAILED)
  end

  def update_last_run!
    update!(last_run_at: Time.current)
  end

  def should_run_now?
    return false unless recurring?
    return false if status == STATUS_PAUSED
    return false if end_date.present? && Time.current > end_date

    # Check if it's time to run based on cron expression
    if last_run_at.present?
      next_run = parse_cron_next_time(last_run_at)
      Time.current >= next_run if next_run
    else
      # First run for recurring campaign
      true
    end
  end

  private

  # def set_default_status
  #   self.status ||= STATUS_SCHEDULED
  # end

  # def scheduled_at_required_for_one_time
  #   if one_time? && scheduled_at.blank?
  #     errors.add(:scheduled_at, "is required for one-time campaigns")
  #   end
  # end

  # def cron_expression_required_for_recurring
  #   if recurring? && cron_expression.blank?
  #     errors.add(:cron_expression, "is required for recurring campaigns")
  #   end
  # end

  # def end_date_after_scheduled_at
  #   if scheduled_at.present? && end_date.present? && end_date <= scheduled_at
  #     errors.add(:end_date, "must be after scheduled time")
  #   end
  # end

  # def validate_cron_expression_format
  #   return unless recurring? && cron_expression.present?

  #   begin
  #     require "fugit"
  #     Fugit.parse_cron(cron_expression)
  #   rescue => e
  #     errors.add(:cron_expression, "is not a valid cron expression: #{e.message}")
  #   end
  # end

  # def parse_cron_next_time(from_time)
  #   require "fugit"
  #   cron = Fugit.parse_cron(cron_expression)
  #   cron&.next_time(from_time)&.to_time
  # rescue => e
  #   Rails.logger.error "Error parsing cron expression: #{e.message}"
  #   nil
  # end
end
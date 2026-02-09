class CampaignSend < ApplicationRecord
  # Constants
  STATUS_QUEUED = "queued".freeze
  STATUS_SENT = "sent".freeze
  STATUS_FAILED = "failed".freeze

  VALID_STATUSES = [ STATUS_QUEUED, STATUS_SENT, STATUS_FAILED ].freeze

  # Associations
  belongs_to :campaign
  belongs_to :contact

  # Validations
  validates :campaign_id, presence: true
  validates :contact_id, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }

  # Scopes
  scope :queued, -> { where(status: STATUS_QUEUED) }
  scope :sent, -> { where(status: STATUS_SENT) }
  scope :failed, -> { where(status: STATUS_FAILED) }

  # Instance methods
  def mark_as_sent!
    update!(status: STATUS_SENT, sent_at: Time.current)
  end

  def mark_as_failed!(error_msg)
    update!(status: STATUS_FAILED, error_message: error_msg)
  end
end

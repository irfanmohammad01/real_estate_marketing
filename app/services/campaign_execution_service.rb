class CampaignExecutionService
  class ExecutionError < StandardError; end

  def self.call(campaign_id)
    new(campaign_id).execute
  end

  def initialize(campaign_id)
    @campaign_id = campaign_id
  end

  def execute
    load_campaign!
    verify_campaign_can_run!

    @campaign.mark_as_running!

    contacts = collect_all_contacts

    if contacts.empty?
      @campaign.mark_as_completed!
      Rails.logger.info "Campaign #{@campaign.id} completed with 0 recipients"
      return { campaign_id: @campaign.id, total_recipients: 0 }
    end

    queue_email_sends(contacts)
    @campaign.update_last_run!

    # For one-time campaigns, they stay in 'running' status until all emails are sent
    # For recurring campaigns, they revert to 'scheduled' status
    @campaign.update!(status: Campaign::STATUS_SCHEDULED) if @campaign.recurring?

    {
      campaign_id: @campaign.id,
      total_recipients: contacts.count,
      status: "queued"
    }
  rescue => e
    @campaign&.mark_as_failed!
    Rails.logger.error "Campaign execution failed: #{e.message}\n#{e.backtrace.join("\n")}"
    raise ExecutionError, "Campaign execution failed: #{e.message}"
  end

  private

  attr_reader :campaign_id

  def load_campaign!
    @campaign = Campaign.includes(:email_template, :audiences).find(campaign_id)
  rescue ActiveRecord::RecordNotFound
    raise ExecutionError, "Campaign not found"
  end

  def verify_campaign_can_run!
    if @campaign.email_template.nil?
      raise ExecutionError, "Email template has been deleted"
    end

    if @campaign.status == Campaign::STATUS_RUNNING
      raise ExecutionError, "Campaign is already running"
    end

    if @campaign.status == Campaign::STATUS_PAUSED
      raise ExecutionError, "Campaign is paused"
    end

    if @campaign.audiences.empty?
      raise ExecutionError, "Campaign has no audiences"
    end
  end

  def collect_all_contacts
    all_contacts = []

    @campaign.audiences.each do |audience|
      matching_contacts = audience.matching_contacts

      matching_contacts.each do |contact|
        all_contacts << contact
      end
    end

    # User wants duplicates, so we don't use .uniq
    Rails.logger.info "Campaign #{@campaign.id}: Found #{all_contacts.count} total recipients (including duplicates)"
    all_contacts
  end

  def queue_email_sends(contacts)
    contacts.each do |contact|
      # Create campaign send record
      campaign_send = CampaignSend.create!(
        campaign_id: @campaign.id,
        contact_id: contact.id,
        email: contact.email,
        status: CampaignSend::STATUS_QUEUED
      )

      # Queue worker for sending email
      EmailSendWorker.perform_async(campaign_send.id)
    end

    Rails.logger.info "Queued #{contacts.count} emails for campaign #{@campaign.id}"
  end
end

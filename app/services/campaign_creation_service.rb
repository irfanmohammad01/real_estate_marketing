class CampaignCreationService
  class ValidationError < StandardError; end

  def self.call(campaign_params, audience_ids, organization_id)
    new(campaign_params, audience_ids, organization_id).create
  end

  def initialize(campaign_params, audience_ids, organization_id)
    @campaign_params = campaign_params
    @audience_ids = audience_ids || []
    @organization_id = organization_id
  end

  def create
    validate_inputs!

    campaign = nil

    ActiveRecord::Base.transaction do
      campaign = create_campaign!
      link_audiences!(campaign)
    end

    schedule_execution(campaign) if campaign.one_time? && campaign.scheduled_at > Time.current

    campaign
  rescue ActiveRecord::RecordInvalid => e
    raise ValidationError, e.message
  end

  private

  attr_reader :campaign_params, :audience_ids, :organization_id

  def validate_inputs!
    raise ValidationError, "At least one audience is required" if audience_ids.empty?

    validate_email_template!
    validate_audiences!
    validate_schedule!
  end

  def validate_email_template!
    template_id = campaign_params[:email_template_id]
    template = EmailTemplate.find_by(id: template_id, organization_id: organization_id)

    raise ValidationError, "Email template not found" unless template
  end

  def validate_audiences!
    audiences = Audience.where(id: audience_ids, organization_id: organization_id)

    if audiences.count != audience_ids.uniq.count
      raise ValidationError, "One or more audiences not found or not accessible"
    end
  end

  def validate_schedule!
    schedule_type_name = ScheduleType.find_by(id: campaign_params[:schedule_type_id])&.name

    case schedule_type_name
    when ScheduleType::ONE_TIME
      if campaign_params[:scheduled_at].blank?
        raise ValidationError, "Scheduled time is required for one-time campaigns"
      end

      if campaign_params[:scheduled_at].to_time < Time.current
        raise ValidationError, "Scheduled time must be in the future"
      end
    when ScheduleType::RECURRING
      if campaign_params[:cron_expression].blank?
        raise ValidationError, "Cron expression is required for recurring campaigns"
      end
    else
      raise ValidationError, "Invalid schedule type"
    end

    if campaign_params[:end_date].present? && campaign_params[:scheduled_at].present?
      if campaign_params[:end_date].to_time <= campaign_params[:scheduled_at].to_time
        raise ValidationError, "End date must be after scheduled time"
      end
    end
  end

  def create_campaign!
    Campaign.create!(campaign_params.merge(organization_id: organization_id))
  end

  def link_audiences!(campaign)
    audience_ids.each do |audience_id|
      CampaignAudience.create!(campaign_id: campaign.id, audience_id: audience_id)
    end
  end

  def schedule_execution(campaign)
    # Schedule the campaign execution worker for the future
    scheduled_time = campaign.scheduled_at
    delay_seconds = (scheduled_time - Time.current).to_i

    CampaignExecutionWorker.perform_in(delay_seconds.seconds, campaign.id)
    Rails.logger.info "Campaign #{campaign.id} scheduled for execution at #{scheduled_time}"
  rescue => e
    Rails.logger.error "Failed to schedule campaign execution: #{e.message}"
  end
end

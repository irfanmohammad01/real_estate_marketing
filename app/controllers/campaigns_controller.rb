class CampaignsController < ApplicationController
  before_action -> { authorize_org_member!("ORG_ADMIN", "ORG_USER") }
  before_action :set_campaign, only: [ :show, :pause, :resume, :destroy, :stats, :sends ]

  # GET /campaigns
  def index
    campaigns = Campaign
      .includes(:email_template, :schedule_type, :audiences)
      .where(organization_id: current_user.organization_id)

    # Filter by status if provided
    campaigns = campaigns.where(status: params[:status]) if params[:status].present?

    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 25

    campaigns = campaigns.page(page).per(per_page)

    render json: {
      campaigns: campaigns.map { |c| campaign_summary(c) },
      pagination: {
        current_page: campaigns.current_page,
        total_pages: campaigns.total_pages,
        total_count: campaigns.total_count,
        per_page: per_page.to_i
      }
    }
  rescue => e
    Rails.logger.error "Error fetching campaigns: #{e.message}"
    render json: { error: "Failed to fetch campaigns", message: e.message }, status: :internal_server_error
  end

  # GET /campaigns/:id
  def show
    render json: campaign_detail(@campaign)
  end

  # POST /campaigns
  def create
    campaign_params = params.require(:campaign).permit(
      :name,
      :email_template_id,
      :schedule_type_id,
      :scheduled_at,
      :cron_expression,
      :end_date
    )

    # Handle schedule_type by name (convert to ID)
    if params[:campaign][:schedule_type].present?
      schedule_type = ScheduleType.find_by(name: params[:campaign][:schedule_type])
      if schedule_type
        campaign_params[:schedule_type_id] = schedule_type.id
      else
        return render json: { error: "Invalid schedule type" }, status: :unprocessable_entity
      end
    end

    audience_ids = params[:audience_ids] || []

    campaign = CampaignCreationService.call(
      campaign_params,
      audience_ids,
      current_user.organization_id
    )

    render json: campaign_detail(campaign), status: :created
  rescue CampaignCreationService::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "Campaign creation error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Failed to create campaign", message: e.message }, status: :internal_server_error
  end

  # POST /campaigns/:id/pause
  def pause
    unless @campaign.can_be_paused?
      return render json: { error: "Cannot pause campaign in #{@campaign.status} status" }, status: :unprocessable_entity
    end

    @campaign.pause!
    render json: { message: "Campaign paused successfully", campaign: campaign_summary(@campaign) }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /campaigns/:id/resume
  def resume
    unless @campaign.can_be_resumed?
      return render json: { error: "Cannot resume campaign in #{@campaign.status} status" }, status: :unprocessable_entity
    end

    @campaign.resume!

    # Reschedule one-time campaign if needed
    if @campaign.one_time? && @campaign.scheduled_at > Time.current
      delay_seconds = (@campaign.scheduled_at - Time.current).to_i
      CampaignExecutionWorker.perform_in(delay_seconds.seconds, @campaign.id)
    end

    render json: { message: "Campaign resumed successfully", campaign: campaign_summary(@campaign) }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /campaigns/:id
  def destroy
    unless @campaign.can_be_cancelled?
      return render json: { error: "Cannot cancel campaign in #{@campaign.status} status" }, status: :unprocessable_entity
    end

    @campaign.cancel!
    render json: { message: "Campaign cancelled successfully" }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /campaigns/:id/stats
  def stats
    total_sends = @campaign.campaign_sends.count
    total_sent = @campaign.campaign_sends.sent.count
    total_failed = @campaign.campaign_sends.failed.count
    total_queued = @campaign.campaign_sends.queued.count

    render json: {
      campaign_id: @campaign.id,
      campaign_name: @campaign.name,
      status: @campaign.status,
      total_queued: total_queued,
      total_sent: total_sent,
      total_failed: total_failed,
      total_sends: total_sends,
      audiences_count: @campaign.audiences.count,
      last_run_at: @campaign.last_run_at,
      created_at: @campaign.created_at
    }
  end

  # GET /campaigns/:id/sends
  def sends
    campaign_sends = @campaign.campaign_sends.includes(:contact)

    # Filter by status if provided
    campaign_sends = campaign_sends.where(status: params[:send_status]) if params[:send_status].present?

    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 25

    campaign_sends = campaign_sends.page(page).per(per_page)

    render json: {
      sends: campaign_sends.map { |cs|
        {
          id: cs.id,
          contact_id: cs.contact_id,
          contact_name: "#{cs.contact.first_name} #{cs.contact.last_name}".strip,
          email: cs.email,
          status: cs.status,
          sent_at: cs.sent_at,
          error_message: cs.error_message,
          created_at: cs.created_at
        }
      },
      pagination: {
        current_page: campaign_sends.current_page,
        total_pages: campaign_sends.total_pages,
        total_count: campaign_sends.total_count,
        per_page: per_page.to_i
      }
    }
  end

  private

  def set_campaign
    @campaign = Campaign.find_by(id: params[:id], organization_id: current_user.organization_id)
    render json: { error: "Campaign not found" }, status: :not_found unless @campaign
  end

  def campaign_summary(campaign)
    {
      id: campaign.id,
      name: campaign.name,
      status: campaign.status,
      schedule_type: campaign.schedule_type.name,
      scheduled_at: campaign.scheduled_at,
      cron_expression: campaign.cron_expression,
      end_date: campaign.end_date,
      last_run_at: campaign.last_run_at,
      created_at: campaign.created_at,
      email_template_name: campaign.email_template&.name,
      audiences_count: campaign.audiences.count
    }
  end

  def campaign_detail(campaign)
    campaign_summary(campaign).merge(
      email_template: {
        id: campaign.email_template.id,
        name: campaign.email_template.name,
        subject: campaign.email_template.subject
      },
      audiences: campaign.audiences.map { |a|
        {
          id: a.id,
          name: a.name,
          bhk_type: a.bhk_type&.name,
          furnishing_type: a.furnishing_type&.name,
          location: a.location&.city,
          property_type: a.property_type&.name,
          power_backup_type: a.power_backup_type&.name
        }
      }
    )
  end
end

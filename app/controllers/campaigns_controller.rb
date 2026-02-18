class CampaignsController < ApplicationController
  before_action -> { authorize_org_member!("ORG_ADMIN", "ORG_USER") }
  before_action :set_campaign, only: [ :update, :destroy ]

  def index
    @campaigns = Campaign.all
    render json: @campaigns.as_json(except: [ :updated_at, :deleted_at ]), status: :ok
  end

  def create
    @campaign = Campaign.new(campaign_params)
    audience_id = params[:audience_id]
    @campaign.organization_id = current_user.organization_id
    @campaign.schedule_type_id = ScheduleType.find_by(name: ScheduleType::SCHEDULE_TYPES[:ONE_TIME])&.id
    @campaign.status = Campaign::STATUS_SCHEDULED
    if @campaign.save
      process_email_to_audience(
        audience_id,
        @campaign.email_template_id,
        @campaign.scheduled_at
      )
      render json: @campaign.as_json(except: [ :updated_at, :deleted_at ]), status: :created
    else
      render json: { errors: @campaign.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @campaign.update(campaign_params)
      render json: @campaign.as_json(except: [ :updated_at, :deleted_at ]), status: :ok
    else
      render json: { errors: @campaign.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.destroy
    render json: { message: "Campaign deleted successfully" }, status: :ok
  end

  def send_email_to_audience
    result = process_email_to_audience(
      send_email_to_audience_params[:audience_id],
      send_email_to_audience_params[:email_template_id],
      Time.zone.parse(send_email_to_audience_params[:scheduled_at]))

    if result[:error]
      render json: { error: result[:error] }, status: :not_found
    else
      render json: { message: "Queued #{result[:count]} emails", count: result[:count] }
    end
  end

  private

  def process_email_to_audience(audience_id, email_template_id, scheduled_at = nil)
    audience = Audience.find_by(id: audience_id, organization_id: current_user.organization_id)
    unless audience
      return { error: "Audience not found" }
    end

    matching_contracts = Contact.joins(:preferences).where(organization_id: current_user.organization_id).distinct

    conditions = []
    conditions << "preferences.bhk_type_id = #{audience.bhk_type_id}" if audience.bhk_type_id
    conditions << "preferences.furnishing_type_id = #{audience.furnishing_type_id}" if audience.furnishing_type_id
    conditions << "preferences.location_id = #{audience.location_id}" if audience.location_id
    conditions << "preferences.property_type_id = #{audience.property_type_id}" if audience.property_type_id
    conditions << "preferences.power_backup_type_id = #{audience.power_backup_type_id}" if audience.power_backup_type_id

    if conditions.any?
      matching_contracts = matching_contracts.where(conditions.join(" OR "))
    end
    count = 0
    matching_contracts.find_each do |contact|
      if scheduled_at.present?
        EmailSenderWorker.perform_at(scheduled_at, contact.email, email_template_id, current_user.organization_id)
      else
        EmailSenderWorker.perform_async(contact.email, email_template_id, current_user.organization_id)
      end
      count += 1
    end

    { count: count }
  end

  def send_email_to_audience_params
    params.permit(:audience_id, :email_template_id, :scheduled_at)
  end


  def set_campaign
    @campaign = Campaign.find(params[:id])
  end


  def campaign_params
    params.permit(:name, :email_template_id, :scheduled_at)
  end
end

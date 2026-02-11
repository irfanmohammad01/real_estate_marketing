class CampaignsController < ApplicationController
  def index
    @campaigns = Campaign.all
  end

  def create
    @campaign = Campaign.new(campaign_params)
    # mail
    if @campaign.save
      redirect_to @campaign
    else
      render :new
    end
  end
  private
  def campaign_params
    params.require(:campaign).permit(:name, :email_template_id, :schedule_type, :scheduled_at, :end_date, :cron_expression)
  end
end

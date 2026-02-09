class CampaignExecutionWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, queue: :campaigns

  def perform(campaign_id)
    CampaignExecutionService.call(campaign_id)

    # After execution completes, check if all emails are sent
    check_campaign_completion(campaign_id)
  rescue CampaignExecutionService::ExecutionError => e
    Rails.logger.error "Campaign execution worker failed: #{e.message}"
    # Campaign already marked as failed in the service
  rescue => e
    Rails.logger.error "Unexpected error in campaign execution: #{e.message}\n#{e.backtrace.join("\n")}"

    campaign = Campaign.find_by(id: campaign_id)
    campaign&.mark_as_failed!

    raise # Re-raise to trigger Sidekiq retry
  end

  private

  def check_campaign_completion(campaign_id)
    campaign = Campaign.find(campaign_id)
    return unless campaign.one_time? # Only check completion for one-time campaigns

    total_sends = campaign.campaign_sends.count
    return if total_sends.zero?

    completed_sends = campaign.campaign_sends.where(status: [ CampaignSend::STATUS_SENT, CampaignSend::STATUS_FAILED ]).count

    if completed_sends >= total_sends
      campaign.mark_as_completed!
      Rails.logger.info "Campaign #{campaign_id} marked as completed (#{completed_sends}/#{total_sends} emails processed)"
    end
  end
end

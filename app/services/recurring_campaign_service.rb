class RecurringCampaignService
  def self.check_and_queue
    new.check_and_queue
  end

  def check_and_queue
    recurring_campaigns = Campaign
      .includes(:schedule_type)
      .where(schedule_types: { name: ScheduleType::RECURRING })
      .where(status: [ Campaign::STATUS_SCHEDULED, Campaign::STATUS_RUNNING ])

    Rails.logger.info "Checking #{recurring_campaigns.count} recurring campaigns..."

    recurring_campaigns.each do |campaign|
      next unless should_execute_now?(campaign)

      # Check if end date has passed
      if campaign.end_date.present? && Time.current > campaign.end_date
        campaign.mark_as_completed!
        Rails.logger.info "Campaign #{campaign.id} ended (past end_date)"
        next
      end

      # Queue execution
      CampaignExecutionWorker.perform_async(campaign.id)
      Rails.logger.info "Queued recurring campaign #{campaign.id} for execution"
    rescue => e
      Rails.logger.error "Error checking campaign #{campaign.id}: #{e.message}"
    end
  end

  private

  def should_execute_now?(campaign)
    return false if campaign.status == Campaign::STATUS_PAUSED
    return false if campaign.cron_expression.blank?

    # If never run, execute now
    return true if campaign.last_run_at.nil?

    # Parse cron and check if it's time
    begin
      require "fugit"
      cron = Fugit.parse_cron(campaign.cron_expression)
      next_run_time = cron.next_time(campaign.last_run_at).to_time

      Time.current >= next_run_time
    rescue => e
      Rails.logger.error "Invalid cron expression for campaign #{campaign.id}: #{e.message}"
      false
    end
  end
end

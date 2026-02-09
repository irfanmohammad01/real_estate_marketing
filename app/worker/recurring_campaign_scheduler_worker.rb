class RecurringCampaignSchedulerWorker
  include Sidekiq::Worker

  sidekiq_options retry: 2, queue: :scheduler

  def perform
    RecurringCampaignService.check_and_queue
  rescue => e
    Rails.logger.error "Recurring campaign scheduler error: #{e.message}\n#{e.backtrace.join("\n")}"
    raise
  end
end

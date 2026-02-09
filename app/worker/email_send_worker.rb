class EmailSendWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3, queue: :emails

  def perform(campaign_send_id)
    campaign_send = CampaignSend.find(campaign_send_id)
    campaign = campaign_send.campaign
    email_template = campaign.email_template
    contact = campaign_send.contact

    # Send email using ActionMailer
    CampaignMailer.campaign_email(
      to: contact.email,
      from_name: email_template.from_name,
      from_email: email_template.from_email,
      reply_to: email_template.reply_to,
      subject: email_template.subject,
      html_body: email_template.html_body,
      text_body: email_template.text_body,
      contact: contact
    ).deliver_now

    # Mark as sent
    campaign_send.mark_as_sent!
    Rails.logger.info "Email sent successfully for campaign_send #{campaign_send_id}"

  rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
    # Invalid email address or permanent failure - don't retry
    campaign_send.mark_as_failed!("Invalid email address: #{e.message}")
    Rails.logger.error "Permanent email failure for campaign_send #{campaign_send_id}: #{e.message}"

  rescue Net::SMTPServerBusy, Net::SMTPAuthenticationError, Timeout::Error => e
    # Temporary failure - retry
    campaign_send.mark_as_failed!("Temporary failure: #{e.message}")
    Rails.logger.error "Temporary email failure for campaign_send #{campaign_send_id}: #{e.message}"
    raise # Trigger Sidekiq retry

  rescue => e
    # Unknown error
    campaign_send.mark_as_failed!("Error: #{e.message}")
    Rails.logger.error "Unknown email error for campaign_send #{campaign_send_id}: #{e.message}\n#{e.backtrace.join("\n")}"
    raise # Trigger Sidekiq retry
  end
end

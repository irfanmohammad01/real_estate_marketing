class EmailSenderWorker
  include Sidekiq::Worker
  sidekiq_options queue: "mailers"

  def perform(emails, email_template_id, organization_id)
    template = EmailTemplate.find_by(id: email_template_id, organization_id: organization_id)
    failed_emails = []
    emails.each do |email|
      begin
        UserMailer.generic_email(email, template).deliver_now
      rescue => e
        Rails.logger.error("[Email Failure] #{email} | Template: #{email_template_id} | Error: #{e.message}")
        failed_emails << email
      end
    end
    raise StandardError, "Some emails failed" if failed_emails.any?
  end
end

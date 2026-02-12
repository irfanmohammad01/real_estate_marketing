class EmailSenderWorker
  include Sidekiq::Worker

  def perform(email, email_template_id, organization_id)
    template = EmailTemplate.find_by(id: email_template_id, organization_id: organization_id)
    begin
      UserMailer.generic_email(email, template).deliver_now
    rescue => e
      Rails.logger.error("[Email Failure] #{email} | Template: #{email_template_id} | Error: #{e.message}")
      raise e  
    end
  end
end

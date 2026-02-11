class EmailSenderWorker
  include Sidekiq::Worker

  def perform(email, email_template_id)
    template = EmailTemplate.find_by(id: email_template_id)
    
    unless template
      log_failure(email, email_template_id, "Template not found")
      return
    end

    begin
      UserMailer.generic_email(email, template).deliver_now
    rescue => e
      log_failure(email, email_template_id, e.message)
    end
  end

  private

  def log_failure(email, template_id, error_message)
    log_file = Rails.root.join("log", "email_failures.log")
    
    Dir.mkdir(Rails.root.join("log")) unless Dir.exist?(Rails.root.join("log"))

    logger = Logger.new(log_file)
    logger.error("[#{Time.now}] Failed to send to #{email} (Template: #{template_id}): #{error_message}")
  end
end

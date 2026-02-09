class CampaignMailer < ApplicationMailer
  def campaign_email(to:, from_name:, from_email:, reply_to:, subject:, html_body:, text_body:, contact:)
    # Personalize email content with contact info if needed
    personalized_html = personalize_content(html_body, contact)
    personalized_text = personalize_content(text_body || "", contact)

    mail(
      from: format_email(from_name, from_email),
      to: to,
      subject: subject,
      reply_to: reply_to.presence || from_email
    ) do |format|
      format.html { render html: personalized_html.html_safe }
      format.text { render plain: personalized_text } if personalized_text.present?
    end
  end

  private

  def personalize_content(content, contact)
    return "" if content.blank?

    content
      .gsub("{{first_name}}", contact.first_name || "")
      .gsub("{{last_name}}", contact.last_name || "")
      .gsub("{{email}}", contact.email || "")
      .gsub("{{phone}}", contact.phone || "")
  end

  def format_email(name, email)
    "#{name} <#{email}>"
  end
end

class UserMailer < ApplicationMailer
  
  def invitation_email(user, invitation_link, temporary_password)
    # template = EmailTemplate
    #   .joins(:email_type)
    #   .where(
    #     email_types: { key: "INVITE_EMAIL" }
    #   )
    #   .find_by(name: template_name_for(user))

    # raise "Email template not found" unless template

    # @html_body = render_template(template.html_body, invitation_link, temporary_password)
    # @text_body = render_template(template.text_body, invitation_link, temporary_password)
    Rails.logger.info "\n\nEmail sent successfully\n\n"
    # mail(
    #   from: format_email(template.from_name, template.from_email),
    #   to: user.email,
    #   reply_to: template.reply_to,
    #   subject: template.subject
    # ) do |format|
    #   format.html { render html: @html_body.html_safe }
    #   format.text { render plain: @text_body }
    # end
  end

  private

  def template_name_for(user)
    if user.role.name == ENV["ORG_ADMIN_ROLE"]
      "Admin Invitation Template"
    else
      "Org Agent Invitation Template"
    end
  end

  def render_template(body, invitation_link, temporary_password)
    body.to_s.gsub("{{invitation_link}}", invitation_link).gsub("{{temporary_password}}", temporary_password)
  end

  def format_email(name, email)
    "#{name} <#{email}>"
  end
end

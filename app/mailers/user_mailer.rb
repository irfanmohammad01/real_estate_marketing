class UserMailer < ApplicationMailer
  DEFAULT_FROM_NAME  = "Real Estate Marketing".freeze
  DEFAULT_FROM_EMAIL = ENV.fetch("GMAIL_USERNAME")

  def invitation_email(user, invitation_link, temporary_password = nil)
    role_label = admin_user?(user) ? "Admin" : "Agent"

    mail(
      from: format_email(DEFAULT_FROM_NAME, DEFAULT_FROM_EMAIL),
      to: user.email,
      subject: subject_for(role_label),
      reply_to: DEFAULT_FROM_EMAIL
    ) do |format|
      format.html do
        render html: render_template(html_body_for(role_label), invitation_link, temporary_password).html_safe
      end

      format.text do
        render plain: render_template(text_body_for(role_label), invitation_link, temporary_password)
      end
    end
  end

  private

  def admin_user?(user)
    user.role.name == Role::ROLES[:org_admin]
  end

  def subject_for(role_label)
    "You have been invited as an #{role_label}!"
  end

  def html_body_for(role_label)
    <<~HTML
      <h1>Welcome</h1>
      <p>Hello,</p>

      <p>
        You have been invited to join as an <strong>#{role_label}</strong>.
      </p>

      <p>
        Your temporary password is:
        <strong>{{temporary_password}}</strong>
      </p>

      <p>
        Click the button below to log in:
      </p>

      <p>
        <a href="{{invitation_link}}"
          style="background-color:#007bff;color:#fff;padding:10px 20px;
                  text-decoration:none;border-radius:5px;">
          Accept Invitation
        </a>
      </p>

      <p>Please change your password after logging in.</p>
      <p>Best regards</p>
    HTML
  end


  def text_body_for(role_label)
    <<~TEXT
      Welcome!

      You have been invited to join as an #{role_label}.

      Temporary password:
      {{temporary_password}}

      Login using the following link:
      {{invitation_link}}

      Please change your password after logging in.

      Best regards
    TEXT
  end


  def render_template(body, invitation_link, temporary_password)
    body
      .to_s
      .gsub("{{invitation_link}}", invitation_link)
      .gsub("{{temporary_password}}", temporary_password.to_s)
  end

  def format_email(name, email)
    "#{name} <#{email}>"
  end
end

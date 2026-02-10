# # This file should ensure the existence of records required to run the application in every environment (production,
# # development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# # The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
# #
# # Example:
# #
# #   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
# #     MovieGenre.find_or_create_by!(name: genre_name)
# #   end


# Role::ROLES.each do |key, role_name|
#   Role.find_or_create_by!(name: role_name) do |role|
#   end
# end


# default_org = Organization.find_or_create_by!(name: "System Organization") do |org|
#   org.description = "Default system organization for administrative purposes"
#   org.is_system = true
# end

# superuser_role = Role.find_by!(name: Role::ROLES[:superuser])
# User.find_or_create_by!(email: ENV.fetch("SUPERUSER_EMAIL", "[EMAIL_ADDRESS]"), organization_id: default_org.id) do |user|
#   user.full_name = "System Administrator"
#   user.phone = ENV.fetch("SUPERUSER_PHONE", "9876543210")
#   user.password = ENV.fetch("SUPERUSER_PASSWORD", "Geek@123")
#   user.role = superuser_role
#   user.status = "active"
# end


# invite_email_type = EmailType.find_or_create_by!(key: "INVITE_EMAIL") do |type|
#   type.description = "User invitation emails"
# end
# EmailTemplate.find_or_create_by!(
#   organization: default_org,
#   email_type: invite_email_type,
#   name: "User Invitation Template"
# ) do |template|
#   template.subject = "You have been invited!"
#   template.preheader = "Welcome to Real Estate Marketing Platform"
#   template.from_name = "Real Estate Marketing"
#   template.from_email = ENV.fetch("GMAIL_USERNAME", "noreply@example.com")
#   template.reply_to = ENV.fetch("GMAIL_USERNAME", "noreply@example.com")

#   template.html_body = <<~HTML
#     <h1>Welcome!</h1>
#     <p>Hello,</p>

#     <p>You have been invited to join the Real Estate Marketing Platform.</p>

#     <p>Your temporary password is: <strong>{{temporary_password}}</strong></p>

#     <p>
#       <a href="{{invitation_link}}"#{' '}
#          style="background-color:#007bff;color:#fff;padding:10px 20px;
#                 text-decoration:none;border-radius:5px;">
#         Accept Invitation
#       </a>
#     </p>

#     <p>Please change your password after logging in.</p>
#     <p>Best regards,<br>The Team</p>
#   HTML

#   template.text_body = <<~TEXT
#     Welcome!

#     You have been invited to join the Real Estate Marketing Platform.

#     Temporary password: {{temporary_password}}

#     Login using the following link:
#     {{invitation_link}}

#     Please change your password after logging in.

#     Best regards,
#     The Team
#   TEXT
# end

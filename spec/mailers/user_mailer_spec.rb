require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "welcome_email" do
    let(:organization) { Organization.create!(name: "Test Org", description: "Test Organization") }
    let(:role) { Role.create!(name: "org_user") }
    let(:user) { User.create!(full_name: "John Doe", email: "[EMAIL_ADDRESS]", phone: "1234567890", status: "active", password: "Password@123", organization: organization, role: role) }
    let(:mail) { UserMailer.welcome_email(user) }

    # it "renders the headers" do
    #   expect(mail.subject).to eq("Welcome to Our App!")
    #   expect(mail.to).to eq(["[EMAIL_ADDRESS]"])
    #   expect(mail.from).to eq(["[EMAIL_ADDRESS]"])
    # end

    # it "renders the body" do
    #   expect(mail.body.encoded).to match("Hi John Doe,")
    #   expect(mail.body.encoded).to match("Welcome to Our App!")
    #   expect(mail.body.encoded).to match("You can now log in with your email and password.")
    # end
  end

  describe "invitation_email" do
    let(:organization) { Organization.create!(name: "Test Org", description: "Test Organization") }
    let(:admin_role) { Role.create!(name: "ORG_ADMIN") }
    let(:user_role) { Role.create!(name: "ORG_USER") }
    let(:admin_user) { User.create!(full_name: "Admin User", email: "admin@example.com", phone: "9999999999", status: "active", password: "Password@123", organization: organization, role: admin_role) }
    let(:normal_user) { User.create!(full_name: "Normal User", email: "user@example.com", phone: "8888888888", status: "active", password: "Password@123", organization: organization, role: user_role) }
    let(:invitation_link) { "http://example.com/invite" }
    let(:temporary_password) { "TempPass123!" }

    context "when user is an admin" do
      let(:mail) { UserMailer.invitation_email(admin_user, invitation_link, temporary_password) }

      it "renders the headers" do
        expect(mail.subject).to eq("You have been invited as an Admin!")
        expect(mail.to).to eq([admin_user.email])
        expect(mail.from).to include(ENV.fetch("GMAIL_USERNAME"))
      end

      it "renders the body" do
        expect(mail.body.encoded).to match("You have been invited to join as an <strong>Admin</strong>")
        expect(mail.body.encoded).to match(invitation_link)
        expect(mail.body.encoded).to match(temporary_password)
      end
    end

    context "when user is an agent" do
      let(:mail) { UserMailer.invitation_email(normal_user, invitation_link, temporary_password) }

      it "renders the headers" do
        expect(mail.subject).to eq("You have been invited as an Agent!")
        expect(mail.to).to eq([normal_user.email])
        expect(mail.from).to include(ENV.fetch("GMAIL_USERNAME"))
      end

      it "renders the body" do
        expect(mail.body.encoded).to match("You have been invited to join as an <strong>Agent</strong>")
        expect(mail.body.encoded).to match(invitation_link)
        expect(mail.body.encoded).to match(temporary_password)
      end
    end
  end
end

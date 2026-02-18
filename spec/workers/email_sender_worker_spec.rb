require 'rails_helper'

RSpec.describe EmailSenderWorker, type: :worker do
  let(:emails) { [ "test1@example.com", "test2@example.com" ] }
  let(:template) { double("EmailTemplate") }
  let(:email_template_id) { 1 }
  let(:organization_id) { 10 }

  before do
    allow(EmailTemplate).to receive(:find_by)
      .with(id: email_template_id, organization_id: organization_id)
      .and_return(template)
  end

  describe "#perform" do
    context "when all emails are sent successfully" do
      it "sends emails without raising error" do
        mailer_double = double("mailer", deliver_now: true)

        allow(UserMailer).to receive(:generic_email)
          .and_return(mailer_double)

        expect {
          described_class.new.perform(emails, email_template_id, organization_id)
        }.not_to raise_error

        expect(UserMailer).to have_received(:generic_email).twice
      end

      it "is enqueued in mailers queue" do
        expect(described_class.get_sidekiq_options["queue"]).to eq("mailers")
      end
    end

    context "when some emails fail" do
      it "logs error and raises StandardError" do
        allow(UserMailer).to receive(:generic_email)
          .and_raise(StandardError.new("SMTP error"))

        allow(Rails.logger).to receive(:error)

        expect {
          described_class.new.perform(emails, email_template_id, organization_id)
        }.to raise_error(StandardError, "Some emails failed")

        expect(Rails.logger).to have_received(:error).twice
      end

      it "writes error to test log file" do
        log_file = Rails.root.join("log/test.log")
        File.truncate(log_file, 0)

        allow(UserMailer).to receive(:generic_email)
          .and_raise(StandardError.new("SMTP error"))

        begin
          described_class.new.perform(emails, email_template_id, organization_id)
        rescue
        end

        log_content = File.read(log_file)
        expect(log_content).to include("[Email Failure]")
      end
    end
  end
end

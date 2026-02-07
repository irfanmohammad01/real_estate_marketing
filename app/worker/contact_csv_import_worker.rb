class ContactCsvImportWorker
  include Sidekiq::Worker

  def perform(file_path, organization_id)
    file = File.open(file_path)
    ContactCsvImportService.call(file, organization_id)
  ensure
    file.close if file
    File.delete(file_path) if File.exist?(file_path)  # Clean up temp file
  end
end

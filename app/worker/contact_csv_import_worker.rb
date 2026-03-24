class ContactCsvImportWorker
  include Sidekiq::Worker
  sidekiq_options queue: "high_priority"

  def perform(file_path, organization_id)
    Rails.logger.info "[ContactCsvImportWorker] Starting import for organization #{organization_id}"

    file = File.open(file_path)
    result = ContactCsvImportService.call(file, organization_id)

    Rails.logger.info "[ContactCsvImportWorker] Import completed: #{result[:success_count]} success, #{result[:error_count]} errors"
    result
  rescue ContactCsvImportService::CsvValidationError => e
    Rails.logger.error "[ContactCsvImportWorker] CSV validation failed: #{e.message}"
    raise # Re-raise to mark job as failed
  rescue => e
    Rails.logger.error "[ContactCsvImportWorker] Import failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  ensure
    file.close if file
    if File.exist?(file_path)
      File.delete(file_path)
      Rails.logger.info "[ContactCsvImportWorker] Cleaned up temp file: #{file_path}"
    end
  end
end

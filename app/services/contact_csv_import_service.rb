require "csv"

class ContactCsvImportService
  # Required CSV headers
  REQUIRED_HEADERS = %w[
    first_name
    last_name
    email
    phone
    bhk_type
    furnishing_type
    location
    property_type
    power_backup_type
  ].freeze

  class CsvValidationError < StandardError; end

  def self.call(file, organization_id)
    # Validate file and headers before processing
    validate_csv_file!(file)

    success_count = 0
    error_count = 0
    errors = []

    CSV.foreach(file.path, headers: true) do |row|
      begin
        contact = Contact.create!(
          organization_id: organization_id,
          first_name: row["first_name"],
          last_name: row["last_name"],
          email: row["email"],
          phone: row["phone"]
        )

        Preference.create!(
          contact_id: contact.id,
          bhk_type_id: BhkType.find_by(name: row["bhk_type"])&.id,
          furnishing_type_id: FurnishingType.find_by(name: row["furnishing_type"])&.id,
          location_id: Location.find_by(city: row["location"])&.id,
          property_type_id: PropertyType.find_by(name: row["property_type"])&.id,
          power_backup_type_id: PowerBackupType.find_by(name: row["power_backup_type"])&.id
        )

        success_count += 1
      rescue => e
        error_count += 1
        error_msg = "Row (#{row['email']}): #{e.message}"
        Rails.logger.error "CSV Import Error: #{error_msg}"
        errors << error_msg
      end
    end

    Rails.logger.info "CSV Import Complete: #{success_count} successful, #{error_count} errors"
    { success_count: success_count, error_count: error_count, errors: errors }
  end

  private

  def self.validate_csv_file!(file)
    # Check if file exists and is readable
    unless file.respond_to?(:path) && File.exist?(file.path)
      raise CsvValidationError, "Invalid file or file does not exist"
    end

    # Check file extension
    file_extension = File.extname(file.path).downcase
    unless file_extension == ".csv"
      raise CsvValidationError, "Invalid file type. Only CSV files are allowed. Received: #{file_extension}"
    end

    # Check file is not empty
    if File.zero?(file.path)
      raise CsvValidationError, "CSV file is empty"
    end

    # Validate CSV structure and headers
    begin
      csv_headers = CSV.open(file.path, headers: true, &:first)&.headers

      unless csv_headers
        raise CsvValidationError, "CSV file has no headers"
      end

      # Normalize headers (strip whitespace, downcase)
      csv_headers = csv_headers.map { |h| h&.strip&.downcase }.compact

      # Check for required headers
      missing_headers = REQUIRED_HEADERS - csv_headers

      if missing_headers.any?
        raise CsvValidationError, "Missing required headers: #{missing_headers.join(', ')}. Required headers are: #{REQUIRED_HEADERS.join(', ')}"
      end

      Rails.logger.info "CSV validation passed: All required headers present"
    rescue CSV::MalformedCSVError => e
      raise CsvValidationError, "Invalid CSV format: #{e.message}"
    end
  end
end

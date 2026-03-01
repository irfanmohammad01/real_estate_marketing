require "csv"

class ContactCsvImportService
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
    validate_csv_file!(file)

    contacts_data = []
    preferences_data = []
    errors = []
    batch_size = 1000
    success_count = 0

    bhk_types = BhkType.pluck(:name, :id).to_h
    furnishing_types = FurnishingType.pluck(:name, :id).to_h
    locations = Location.pluck(:city, :id).to_h
    property_types = PropertyType.pluck(:name, :id).to_h
    power_backup_types = PowerBackupType.pluck(:name, :id).to_h

    CSV.foreach(file.path, headers: true).with_index do |row, index|
      begin
        contacts_data << {
          organization_id: organization_id,
          first_name: row["first_name"],
          last_name: row["last_name"],
          email: row["email"],
          phone: row["phone"]
        }

        preferences_data << {
          bhk_type_id: bhk_types[row["bhk_type"]],
          furnishing_type_id: furnishing_types[row["furnishing_type"]],
          location_id: locations[row["location"]],
          property_type_id: property_types[row["property_type"]],
          power_backup_type_id: power_backup_types[row["power_backup_type"]]
        }

        if contacts_data.size >= batch_size
          insert_batch(contacts_data, preferences_data)
          success_count += contacts_data.size
          contacts_data.clear
          preferences_data.clear
        end

      rescue => e
        errors << "Row (#{row['email']}): #{e.message}"
      end
    end

    if contacts_data.any?
      insert_batch(contacts_data, preferences_data)
    end

    {
      success_count: success_count,
      error_count: errors.size,
      errors: errors
    }
  end

  def self.insert_batch(contacts_data, preferences_data)
    ActiveRecord::Base.transaction do
      inserted_contacts = Contact.insert_all!(contacts_data, returning: %w[id])

      inserted_ids = inserted_contacts.rows.flatten

      preferences_data.each_with_index do |pref, index|
        pref[:contact_id] = inserted_ids[index]
      end

      Preference.insert_all!(preferences_data)
    end
  end

  private

  def self.validate_csv_file!(file)
    unless file.respond_to?(:path) && File.exist?(file.path)
      raise CsvValidationError, "Invalid file or file does not exist"
    end

    file_extension = File.extname(file.path).downcase
    unless file_extension == ".csv"
      raise CsvValidationError, "Invalid file type. Only CSV files are allowed. Received: #{file_extension}"
    end

    if File.zero?(file.path)
      raise CsvValidationError, "CSV file is empty"
    end

    begin
      csv_headers = CSV.open(file.path, headers: true, &:first)&.headers

      unless csv_headers
        raise CsvValidationError, "CSV file has no headers"
      end


      csv_headers = csv_headers.map { |h| h&.strip&.downcase }.compact
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

require "csv"

class ContactCsvImportService
  def self.call(file, organization_id)
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
end

class ContactsController < ApplicationController
  before_action -> { authorize_org_member!("ORG_ADMIN", "ORG_USER") }

  def create
    contact = Contact.new(contact_params)
    contact.organization_id = current_user.organization_id

    ActiveRecord::Base.transaction do
      contact.save!

      if params[:preference].present?
        Preference.create!(
          contact_id: contact.id,
          bhk_type_id: BhkType.find_by(name: params[:preference][:bhk_type])&.id,
          furnishing_type_id: FurnishingType.find_by(name: params[:preference][:furnishing_type])&.id,
          location_id: Location.find_by(city: params[:preference][:location])&.id,
          property_type_id: PropertyType.find_by(name: params[:preference][:property_type])&.id,
          power_backup_type_id: PowerBackupType.find_by(name: params[:preference][:power_backup_type])&.id
        )
      end
    end

    render json: contact, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def import
    uploaded_file = params[:file]

    # Try to extract from raw multipart body if not properly parsed
    if uploaded_file.nil? && request.content_type&.include?("multipart/form-data")
      result = extract_file_from_raw_body
      uploaded_file = result[:file] if result
      @extracted_filename = result[:filename] if result
    end

    unless uploaded_file
      render json: { error: "No file uploaded. Please provide a file parameter." }, status: :unprocessable_entity
      return
    end

    # Get filename - handle both ActionDispatch::Http::UploadedFile and StringIO
    if uploaded_file.respond_to?(:original_filename)
      filename = uploaded_file.original_filename
    elsif @extracted_filename
      filename = @extracted_filename
    else
      filename = "uploaded_file.csv"  # Default for StringIO
    end

    file_extension = File.extname(filename).downcase

    unless file_extension == ".csv"
      render json: {
        error: "Invalid file type",
        message: "Only CSV files are allowed. You uploaded: #{filename}"
      }, status: :unprocessable_entity
      return
    end

    organization_id = current_user.organization_id
    timestamp = Time.now.to_i
    tmp_path = Rails.root.join("tmp", "contacts_#{timestamp}.csv")

    # Write to temp file - handle both types of file objects
    File.open(tmp_path, "wb") do |f|
      if uploaded_file.respond_to?(:read)
        uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
        f.write(uploaded_file.read)
      else
        f.write(uploaded_file.to_s)
      end
    end

    # Perform early validation on headers
    begin
      ContactCsvImportService.send(:validate_csv_file!, File.open(tmp_path))
    rescue ContactCsvImportService::CsvValidationError => e
      File.delete(tmp_path) if File.exist?(tmp_path)
      render json: {
        error: "CSV validation failed",
        message: e.message
      }, status: :unprocessable_entity
      return
    end

    ContactCsvImportWorker.perform_async(tmp_path.to_s, organization_id)

    render json: { message: "CSV validation passed. Import started successfully." }, status: :accepted
  rescue => e
    Rails.logger.error "Import error: #{e.message}\n#{e.backtrace.join("\n")}"
    # Clean up temp file on error
    File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
    render json: { error: "Failed to import file", message: e.message }, status: :unprocessable_entity
  end

  def paginated
    page = params[:page] || 1
    per_page = params[:per_page] || 25

    @contacts = Contact.where(organization_id: current_user.organization_id)
                       .page(page)
                       .per(per_page)

    render json: {
      contacts: @contacts,
      pagination: {
        current_page: @contacts.current_page,
        total_pages: @contacts.total_pages,
        total_count: @contacts.total_count,
        per_page: per_page.to_i
      }
    }
  end

  def index
    @contacts = Contact.where(organization_id: current_user.organization_id)
    render json: @contacts
  end

  private

  def extract_file_from_raw_body
    multipart_param = params.keys.find { |k| k.include?("Content-Disposition") }
    return nil unless multipart_param

    raw_content = params[multipart_param]

    # Extract filename from Content-Disposition header
    filename_match = multipart_param.match(/filename="([^"]+)"/)
    filename = filename_match ? filename_match[1] : "uploaded_file.csv"

    # Extract file content
    content_start = raw_content.index("\r\n\r\n")
    return nil unless content_start

    content_start += 4
    content_end = raw_content.rindex("\r\n---")
    return nil unless content_end

    csv_content = raw_content[content_start...content_end]

    # Return both file and filename
    { file: StringIO.new(csv_content), filename: filename }
  rescue => e
    Rails.logger.error "Manual parsing failed: #{e.message}"
    nil
  end

  def contact_params
    params.require(:contact).permit(
      :first_name,
      :last_name,
      :email,
      :phone
    )
  end
end

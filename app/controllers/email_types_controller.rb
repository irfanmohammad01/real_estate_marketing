class EmailTypesController < ApplicationController
  before_action -> { authorize_org_member!(Role::ROLES[:org_admin], Role::ROLES[:org_user]) }

  def create
    email_type = EmailType.new(email_type_params)

    if email_type.save
      render json: email_type, status: :created
    else
      render json: { error: "Failed to create email type", message: email_type.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    begin
      render json: EmailType.all
    rescue => e
      Rails.logger.error "Failed to fetch email types: #{e.message}"
      render json: { error: "Failed to retrieve email types", message: e.message }, status: :internal_server_error
    end
  end


  private

  def email_type_params
    params.require(:email_type).permit(:key, :description)
  end
end

class OrganizationsController < ApplicationController
  before_action :authorize_super_user!
  before_action :set_organization, only: [ :show, :update, :destroy, :restore ]

  # GET /organizations
  def index
    @organizations = Organization.all
    render json: @organizations
  end

  # GET /organizations/:id
  def show
    render json: @organization
  end

  # POST /organizations
  def create
    unless params[:organization].present?
      return render json: {
        errors: { organization: [ "Organization parameters are required" ] }
      }, status: :bad_request
    end

    unless params[:user].present?
      return render json: {
        errors: { user: [ "User parameters are required" ] }
      }, status: :bad_request
    end

    organization = nil
    user = nil

    ActiveRecord::Base.transaction do

      organization = Organization.new(organization_params)
      unless organization.save
        render json: { errors: { organization: organization.errors.full_messages } }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end

      role = Role.find_by(name: ENV["ORG_ADMIN_ROLE"])
      unless role
        render json: {
          errors: { role: [ "ORG_ADMIN role not found in database. Please ensure roles are seeded." ] }
        }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end

      user = User.new(user_params)
      user.organization_id = organization.id
      user.role = role
      user.status = ENV["ORG_ADMIN_STATUS"]
      user.password = ENV["INTIAL_PASSWORD"]

      unless user.save
        render json: { errors: { user: user.errors.full_messages } }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end

      begin
        invitation_link = ENV["INVITATION_LINK"]
        password = ENV["INTIAL_PASSWORD"]
        if invitation_link.present?
          UserMailer.invitation_email(user, invitation_link, password).deliver_later
        else
          Rails.logger.warn "INVITATION_LINK not configured. Skipping invitation email."
        end
      rescue => e
        Rails.logger.error "Failed to send invitation email: #{e.message}"
      end

      render json: {
        message: "Organization and first user created successfully",
        organization: organization,
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          phone: user.phone,
          status: user.status,
          role: role.name
        }
      }, status: :created
    end
  rescue ActionController::ParameterMissing => e
    render json: {
      errors: { params: [ "Missing required parameter: #{e.param}" ] }
    }, status: :bad_request
  end


  # PATCH /organizations/:id
  def update
    if @organization.update(organization_params)
      render json: @organization
    else
      render json: { errors: @organization.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /organizations/:id
  def destroy
    @organization.destroy
    render json: { message: "Organization was soft deleted " }
  end

  def restore
    @organization.restore
    render json: { message: "Organization was restored successfully" }
  end

  private

  def set_organization
    @organization = Organization.with_deleted.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :description, :full)
  end

  def user_params
    params.require(:user).permit(
      :full_name,
      :email,
      :phone
    )
  end
end

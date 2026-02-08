class OrganizationsController < ApplicationController
  before_action :authorize_super_user!
  before_action :set_organization, only: [ :show, :update, :destroy, :restore ]

  # def index
  #   @organizations = Organization.all
  #   render json: @organizations
  # end

  def index
    begin
      organizations = Organization
                      .includes(users: :role)

      render json: organizations.map { |org|
      {
        id: org.id,
          name: org.name,
          description: org.description,
          org_admins: org.users.select { |u|
            u.role.name == Role::ROLES[:org_admin]
          }.map { |u|
            {
              id: u.id,
              full_name: u.full_name,
              email: u.email,
              phone: u.phone,
              status: u.status,
              role: u.role.name
            }
          }
        }
      }
    rescue => e
      Rails.logger.error "Failed to fetch organizations: #{e.message}"
      render json: { error: "Failed to retrieve organizations", message: e.message }, status: :internal_server_error
    end
  end


  def show
    begin
      org_admins = @organization.users
                              .joins(:role)
                              .where(roles: { name: Role::ROLES[:org_admin] })
                              .select(
                                "users.id,
                                 users.full_name,
                                 users.email,
                                 users.phone,
                                 users.status,
                                 roles.name AS role_name"
                              )

      render json: {
        organization: @organization,
        org_admins: org_admins.map do |user|
          {
            id: user.id,
            full_name: user.full_name,
            email: user.email,
            phone: user.phone,
            status: user.status,
            role: user.role_name
          }
        end
      }
    rescue => e
      Rails.logger.error "Failed to fetch organization details: #{e.message}"
      render json: { error: "Failed to retrieve organization", message: e.message }, status: :internal_server_error
    end
  end

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

      role = Role.find_by(name: Role::ROLES[:org_admin])
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
      temporary_password = PasswordGenerator.generate_password(length: 10, uppercase: true, lowercase: true, digits: true, symbols: true)
      user.password = temporary_password

      unless user.save
        render json: { errors: { user: user.errors.full_messages } }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end

      begin
        invitation_link = ENV["INVITATION_LINK"]
        if invitation_link.present?
          UserMailer.invitation_email(user, invitation_link, temporary_password).deliver_later
        else
          Rails.logger.warn "INVITATION_LINK not configured. Skipping invitation email."
        end
      rescue => e
        Rails.logger.error "Failed to send invitation email: #{e.message}"
      end

      render json: {
        message: "Organization and first ORG_ADMIN created successfully",
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


  def update
    begin
      if @organization.update(organization_params)
        render json: @organization
      else
        render json: { error: "Update failed", errors: @organization.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Failed to update organization: #{e.message}"
      render json: { error: "Failed to update organization", message: e.message }, status: :internal_server_error
    end
  end

  def destroy
    begin
      @organization.destroy
      render json: { message: "Organization was soft deleted" }
    rescue => e
      Rails.logger.error "Failed to delete organization: #{e.message}"
      render json: { error: "Failed to delete organization", message: e.message }, status: :internal_server_error
    end
  end

  def restore
    begin
      @organization.restore
      render json: { message: "Organization was restored successfully" }
    rescue => e
      Rails.logger.error "Failed to restore organization: #{e.message}"
      render json: { error: "Failed to restore organization", message: e.message }, status: :internal_server_error
    end
  end

  private

  def set_organization
    @organization = Organization.with_deleted.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :description)
  end

  def user_params
    params.require(:user).permit(
      :full_name,
      :email,
      :phone
    )
  end
end

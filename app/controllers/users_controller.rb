class UsersController < ApplicationController
  before_action :authorize_org_admin!
  before_action :set_user, only: [ :update, :show ]

  def index
    begin
      users = User
              .includes(:role, :organization)
              .where(organization_id: current_user.organization_id)

      render json: users.map { |user|
        {
          id: user.id,
          email: user.email,
          role_name: user.role.name,
          organization_name: user.organization.name
        }
      }
    rescue => e
      Rails.logger.error "Failed to fetch users: #{e.message}"
      render json: { error: "Failed to retrieve users", message: e.message }, status: :internal_server_error
    end
  end

  def create
    begin
      role = Role.find_by(name: ENV["ORG_USER_ROLE"])

      unless role
        return render json: {
          error: "Configuration error",
          message: "ORG_USER role not found. Please ensure roles are properly seeded."
        }, status: :internal_server_error
      end

      user = User.new(user_params)
      user.role = role
      user.organization_id = current_user.organization_id
      user.status = ENV["ORG_USER_STATUS"]
      temporary_password = PasswordGenerator.generate_password(length: 10, uppercase: true, lowercase: true, digits: true, symbols: true)
      user.password = temporary_password
      user.jti = SecureRandom.uuid

      if user.save
        begin
          invitation_link = ENV["INVITATION_LINK"]
          Rails.logger.info "Generated password ORG_USER_ROLE: #{temporary_password}"
          if invitation_link.present?
            UserMailer.invitation_email(user, invitation_link, temporary_password).deliver_later
          else
            Rails.logger.warn "INVITATION_LINK not configured. Skipping invitation email."
          end
        rescue => e
          Rails.logger.error "Failed to send invitation email: #{e.message}"
        end
        render json: user.as_json(except: [ :password_digest ]).merge(role_name: user.role.name, organization_name: user.organization.name), status: :created
      else
        render json: { error: "User creation failed", errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Failed to create user: #{e.message}"
      render json: { error: "Failed to create user", message: e.message }, status: :internal_server_error
    end
  end

  def update
    if @user.update(update_user_params)
      render json: @user.as_json(except: [ :password_digest ]).merge(role_name: @user.role.name, organization_name: @user.organization.name)
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
      render json: @user.as_json(except: [ :password_digest ]).merge(role_name: @user.role.name, organization_name: @user.organization.name)
  end

  private

  def set_user
    @user = User.find_by!(
      id: params[:id],
      organization_id: current_user.organization_id
    )
  end

  def user_params
    params.permit(
      :full_name,
      :email,
      :password,
      :phone
    )
  end

  def update_user_params
    params.permit(
      :full_name,
      :phone
    )
  end
end

class UsersController < ApplicationController
  before_action :authorize_org_admin!
  before_action :set_user, only: [ :update, :show ]

  def index
    @users = User.where(organization_id: current_user.organization_id)
    render json: @users
  end

  def create
    role = Role.find_by!(name: ENV["ORG_USER_ROLE"])

    user = User.new(user_params)
    user.role = role
    user.organization_id = current_user.organization_id
    user.status = ENV["ORG_USER_STATUS"]
    temporary_password = PasswordGenerator.generate_password(length: 10, uppercase: true, lowercase: true, digits: true, symbols: true )
    user.password = temporary_password

    if user.save
      begin
        invitation_link = ENV["INVITATION_LINK"]
        if invitation_link.present?
          # UserMailer.invitation_email(user, invitation_link, password).deliver_later
        else
          Rails.logger.warn "INVITATION_LINK not configured. Skipping invitation email."
        end
      rescue => e
        Rails.logger.error "Failed to send invitation email: #{e.message}"
      end
      render json: user, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(update_user_params)
      render json: @user, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    render json: @user
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

# /app/controllers/admin/org_admins_controller.rb

class Admin::OrgAdminsController < ApplicationController
  rate_limit(**DEFAULT_RATE_LIMIT, only: [ :create, :update ])
  before_action :authorize_super_user!, only: [ :create ]
  before_action :authorize_super_or_org_admin!, only: [ :update ]
  before_action :set_user, only: [ :update ]

  def create
    role = Role.find_by!(name: Role::ROLES[:org_admin])
    user = User.new(user_params)
    user.role = role
    user.status = ENV["ORG_ADMIN_STATUS"]
    temporary_password = PasswordGenerator.generate_password(length: 10, uppercase: true, lowercase: true, digits: true, symbols: true)
    user.password = temporary_password

    if user.save
      invitation_link = ENV["INVITATION_LINK"]
      Rails.logger.info "Generated password: #{temporary_password}"
      UserMailer.invitation_email(user, invitation_link, temporary_password).deliver_later
      render json: user.as_json(except: [ :password_digest ]).merge(role_name: user.role.name, organization_name: user.organization.name)
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(update_user_params)
      render json: @user.as_json(except: [ :password_digest ]).merge(role_name: @user.role.name, organization_name: @user.organization.name)
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    if @current_super_user
      @user = User.find_by!(id: params[:id])
    elsif @current_user&.org_admin?
      @user = User.find_by!(id: params[:id], organization_id: @current_user.organization_id)
      # Rails.logger.info "\ninside #{@user.as_json}\n"
    else
      raise ActiveRecord::RecordNotFound, "User not found"
    end
  end

  def update_user_params
    params.require(:user).permit(
      :full_name,
      :phone
    )
  end

  def user_params
    params.require(:user).permit(
      :organization_id,
      :full_name,
      :email,
      :phone
    )
  end
end

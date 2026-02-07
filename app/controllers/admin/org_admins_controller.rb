# /app/controllers/admin/org_admins_controller.rb

class Admin::OrgAdminsController < ApplicationController
  rate_limit(**DEFAULT_RATE_LIMIT, only: [ :create, :update ])
  before_action :authorize_super_user!, only: [ :create ]
  before_action :authorize_super_or_org_admin!, only: [ :update ]
  before_action :set_user, only: [ :update ]

  def create
    role = Role.find_by!(name: ENV["ORG_ADMIN_ROLE"])
    user = User.new(user_params)
    user.role = role
    user.status = ENV["ORG_USER_STATUS"]
    temporary_password = PasswordGenerator.generate_password(length: 10, uppercase: true, lowercase: true, digits: true, symbols: true)
    user.password = temporary_password

    if user.save
      # invitation_link = ENV["INVITATION_LINK"]
      # UserMailer.invitation_email(user, invitation_link, temporary_password).deliver_later
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

  private

  def set_user
    @user = User.find_by!(
      id: params[:id]
    )
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
      :password,
      :phone
    )
  end
end

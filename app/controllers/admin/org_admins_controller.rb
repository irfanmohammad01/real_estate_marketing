# /app/controllers/admin/org_admins_controller.rb

class Admin::OrgAdminsController < ApplicationController
  before_action :authorize_super_user!
  before_action :set_user, only: [ :update ]

  def create
    role = Role.find_by!(name: "ORG_ADMIN")

    user = User.new(user_params)
    user.role = role
    user.status = "active"

    if user.save
      invitation_link = ENV["INVITATION_LINK"]
      temporary_password = ENV["TEMPORARY_PASSWORD"]
      UserMailer.invitation_email(user, invitation_link, temporary_password).deliver_later
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

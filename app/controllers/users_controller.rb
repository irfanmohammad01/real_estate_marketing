class UsersController < ApplicationController
  before_action :authorize_org_admin!
  before_action :set_user, only: [ :update, :show ]

  def index
    @users = User.where(organization_id: current_user.organization_id)
    render json: @users
  end

  def create
    role = Role.find_by!(name: "ORG_USER")

    user = User.new(user_params)
    user.role = role
    user.organization_id = current_user.organization_id
    user.status = "active"

    if user.save
      invitation_link = ENV["INVITATION_LINK"]
      UserMailer.invitation_email(user, invitation_link).deliver_later
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

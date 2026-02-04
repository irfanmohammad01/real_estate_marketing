class OrganizationsController < ApplicationController
  before_action :authorize_super_user!
  before_action :set_organization, only: [:show, :update, :destroy, :restore]

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
    organization = Organization.new(organization_params)

    if organization.save
      render json: organization, status: :created
    else
      render json: { errors: organization.errors.full_messages }, status: :unprocessable_entity
    end
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
    params.require(:organization).permit(:name, :description)
  end
end

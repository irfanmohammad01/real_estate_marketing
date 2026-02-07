class AudiencesController < ApplicationController
  before_action -> { authorize_org_member!("ORG_ADMIN", "ORG_USER") }
  before_action :set_audience, only: [ :show, :update, :destroy ]

  def index
    @audiences = Audience.where(organization_id: current_user.organization_id)
    render json: @audiences
  end

  def show
    render json: @audience
  end

  def create
    preference_ids = Audience.resolve_preference_ids(preference_params)

    audience = Audience.new(audience_params.merge(preference_ids))
    audience.organization_id = current_user.organization_id

    if audience.save
      render json: audience, status: :created
    else
      render json: { errors: audience.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    preference_ids = Audience.resolve_preference_ids(preference_params)

    if @audience.update(audience_params.merge(preference_ids))
      render json: @audience
    else
      render json: { errors: @audience.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @audience.destroy
    render json: { message: "Audience deleted successfully" }
  end

  def restore
    @audience = Audience.only_deleted.find_by(id: params[:id], organization_id: current_user.organization_id)

    if @audience.nil?
      render json: { error: "Deleted audience not found" }, status: :not_found
      return
    end

    @audience.restore
    render json: { message: "Audience restored successfully", audience: @audience }
  end

  private

  def set_audience
    @audience = Audience.find_by(id: params[:id], organization_id: current_user.organization_id)
    render json: { error: "Audience not found" }, status: :not_found unless @audience
  end

  def audience_params
    params.require(:audience).permit(:name)
  end

  def preference_params
    params.fetch(:audience, {}).permit(
      :bhk_type,
      :furnishing_type,
      :location,
      :property_type,
      :power_backup_type
    )
  end
end

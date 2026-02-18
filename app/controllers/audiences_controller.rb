class AudiencesController < ApplicationController
  before_action -> { authorize_org_member!("ORG_ADMIN", "ORG_USER") }
  before_action :set_audience, only: [ :show, :update, :destroy ]

  def index
    @audiences = Audience.where(organization_id: current_user.organization_id)
    render json: @audiences.as_json(except: [ :updated_at, :deleted_at ]), status: :created
  end

  def show
    render json: @audience.as_json(except: [ :updated_at, :deleted_at ]), status: :created
  end

  def create
    audience = Audience.new(audience_params)
    audience.organization_id = current_user.organization_id

    if audience.save
      render json: audience.as_json(except: [ :updated_at, :deleted_at ]), status: :created
    else
      render json: { errors: audience.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @audience.update(audience_params)
      render json: @audience.as_json(except: [ :updated_at, :deleted_at ]), status: :created
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
    params.require(:audience).permit(
      :name,
      :bhk_type_id,
      :furnishing_type_id,
      :location_id,
      :property_type_id,
      :power_backup_type_id
    )
  end
end

class PreferencesController < ApplicationController
  before_action -> { authorize_org_member!("ORG_ADMIN", "ORG_USER") }

  def index
    render json: {
      bhk_types: BhkType.all.select(:id, :name),
      furnishing_types: FurnishingType.all.select(:id, :name),
      property_types: PropertyType.all.select(:id, :name),
      locations: Location.all.select(:id, :city),
      power_backup_types: PowerBackupType.all.select(:id, :name)
    }
  end
end

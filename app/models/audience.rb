class Audience < ApplicationRecord
  acts_as_paranoid

  belongs_to :organization
  belongs_to :bhk_type, optional: true
  belongs_to :furnishing_type, optional: true
  belongs_to :location, optional: true
  belongs_to :property_type, optional: true
  belongs_to :power_backup_type, optional: true

  validates :name, presence: true, uniqueness: { scope: :organization_id, case_sensitive: false }, length: { maximum: 150 }
  validates :organization_id, presence: true

  def self.resolve_preference_ids(params)
    resolved = {}

    resolved[:bhk_type_id] = params[:bhk_type].present? ? BhkType.find_by(name: params[:bhk_type])&.id : nil
    resolved[:furnishing_type_id] = params[:furnishing_type].present? ? FurnishingType.find_by(name: params[:furnishing_type])&.id : nil
    resolved[:location_id] = params[:location].present? ? Location.find_by(city: params[:location])&.id : nil
    resolved[:property_type_id] = params[:property_type].present? ? PropertyType.find_by(name: params[:property_type])&.id : nil
    resolved[:power_backup_type_id] = params[:power_backup_type].present? ? PowerBackupType.find_by(name: params[:power_backup_type])&.id : nil

    resolved
  end

  def as_json(options = {})
    
  end
end

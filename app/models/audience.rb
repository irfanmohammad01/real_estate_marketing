class Audience < ApplicationRecord
  acts_as_paranoid

  belongs_to :organization
  belongs_to :bhk_type, optional: true
  belongs_to :furnishing_type, optional: true
  belongs_to :location, optional: true
  belongs_to :property_type, optional: true
  belongs_to :power_backup_type, optional: true

  has_many :campaign_audiences, dependent: :destroy
  has_many :campaigns, through: :campaign_audiences

  validates :name, presence: true, length: { maximum: 150 }
  validates :organization_id, presence: true

  # Dynamically match contacts based on audience preference criteria
  def matching_contacts
    scope = Contact.joins(:preference).where(organization_id: organization_id)

    scope = scope.where(preferences: { bhk_type_id: bhk_type_id }) if bhk_type_id.present?
    scope = scope.where(preferences: { furnishing_type_id: furnishing_type_id }) if furnishing_type_id.present?
    scope = scope.where(preferences: { location_id: location_id }) if location_id.present?
    scope = scope.where(preferences: { property_type_id: property_type_id }) if property_type_id.present?
    scope = scope.where(preferences: { power_backup_type_id: power_backup_type_id }) if power_backup_type_id.present?

    scope.distinct
  end

  def self.resolve_preference_ids(params)
    resolved = {}

    resolved[:bhk_type_id] = params[:bhk_type].present? ? BhkType.find_by(name: params[:bhk_type])&.id : nil
    resolved[:furnishing_type_id] = params[:furnishing_type].present? ? FurnishingType.find_by(name: params[:furnishing_type])&.id : nil
    resolved[:location_id] = params[:location].present? ? Location.find_by(city: params[:location])&.id : nil
    resolved[:property_type_id] = params[:property_type].present? ? PropertyType.find_by(name: params[:property_type])&.id : nil
    resolved[:power_backup_type_id] = params[:power_backup_type].present? ? PowerBackupType.find_by(name: params[:power_backup_type])&.id : nil

    resolved
  end

  # Custom JSON output with preference labels instead of IDs
  def as_json(options = {})
    super(options.merge(except: [ :bhk_type_id, :furnishing_type_id, :location_id, :property_type_id, :power_backup_type_id ])).merge(
      bhk_type: bhk_type&.name,
      furnishing_type: furnishing_type&.name,
      location: location&.city,
      property_type: property_type&.name,
      power_backup_type: power_backup_type&.name
    )
  end
end

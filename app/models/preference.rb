class Preference < ApplicationRecord
  belongs_to :contact
  belongs_to :bhk_type, optional: true
  belongs_to :furnishing_type, optional: true
  belongs_to :location, optional: true
  belongs_to :property_type, optional: true
  belongs_to :power_backup_type, optional: true
end
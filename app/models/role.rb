class Role < ApplicationRecord
  has_many :users
  validates :name, presence: true, uniqueness: true, length: { maximum: 150 }

  ROLES = {
    org_admin: "ORG_ADMIN",
    org_user: "ORG_USER",
    superuser: "SUPERUSER"
  }.freeze

  def self.org_admin
    find_by!(name: ROLES[:org_admin])
  end

  def self.org_user
    find_by!(name: ROLES[:org_user])
  end

  def self.superuser
    find_by!(name: ROLES[:superuser])
  end
end

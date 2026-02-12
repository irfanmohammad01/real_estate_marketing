# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed reference data for contact preferences
bhk_types = ["1BHK", "2BHK", "3BHK", "4BHK", "5BHK", "Studio"]
bhk_types.each do |name|
  BhkType.find_or_create_by!(name: name)
end

furnishing_types = ["Fully Furnished", "Semi Furnished", "Unfurnished"]
furnishing_types.each do |name|
  FurnishingType.find_or_create_by!(name: name)
end

locations = [
  "Mumbai", "Delhi", "Bangalore", "Hyderabad", "Chennai",
  "Kolkata", "Pune", "Ahmedabad", "Surat", "Jaipur"
]
locations.each do |city|
  Location.find_or_create_by!(city: city)
end

property_types = ["Apartment", "Villa", "Independent House", "Penthouse", "Studio Apartment"]
property_types.each do |name|
  PropertyType.find_or_create_by!(name: name)
end

power_backup_types = ["Full Backup", "Partial Backup", "No Backup"]
power_backup_types.each do |name|
  PowerBackupType.find_or_create_by!(name: name)
end

require "securerandom"
super_user = SuperUser.find_or_initialize_by(email: "super@admin.com")
super_user.password = "Geek@123"
super_user.jti = SecureRandom.uuid
super_user.save!

roles = ["ORG_ADMIN", "ORG_USER"]
roles.each do |name|
  Role.find_or_create_by!(name: name)
end

schedule_types = ["one-time", "recurring"]
schedule_types.each do |name|
  ScheduleType.find_or_create_by!(name: name)
end


puts "Super user created or updated successfully!"

puts "✅ Reference data seeded successfully!"
puts "  - #{BhkType.count} BHK Types"
puts "  - #{FurnishingType.count} Furnishing Types"
puts "  - #{Location.count} Locations"
puts "  - #{PropertyType.count} Property Types"
puts "  - #{PowerBackupType.count} Power Backup Types"

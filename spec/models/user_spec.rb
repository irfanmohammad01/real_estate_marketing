require 'rails_helper'

RSpec.describe User, type: :model do
  # Create organization and role records before each test
  let(:organization) { Organization.create!(name: "Test Org", description: "Test Organization") }
  let(:role) { Role.create!(name: "org_user") }

  it "is valid with a full_name, email, phone, status, password " do
    user = User.new(full_name: "John Doe", email: "john@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: organization, role: role)
    expect(user).to be_valid
  end
  
  it "is invalid without a full_name" do
    user = User.new(email: "john@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: organization, role: role)
    expect(user).not_to be_valid
  end

  it "is invalid without an email" do
    user = User.new(full_name: "John Doe", phone: "1234567890", status: "active", password: "Password@123", organization: organization, role: role)
    expect(user).not_to be_valid
  end

  it "is invalid without a phone" do
    user = User.new(full_name: "John Doe", email: "john@example.com", status: "active", password: "Password@123", organization: organization, role: role)
    expect(user).not_to be_valid
  end

  it "is invalid without a status" do
    user = User.new(full_name: "John Doe", email: "john@example.com", phone: "1234567890", password: "Password@123", organization: organization, role: role)
    expect(user).not_to be_valid
  end

  it "is invalid without a password" do
    user = User.new(full_name: "John Doe", email: "john@example.com", phone: "1234567890", status: "active", organization: organization, role: role)
    expect(user).not_to be_valid
  end

  it "is invalid with a short password" do
    user = User.new(full_name: "John Doe", email: "john@example.com", phone: "1234567890", status: "active", password: "Password", organization: organization, role: role)
    expect(user).not_to be_valid
  end
  
  it "is invalid with a wrong email" do
    user = User.new(full_name: "John Doe", email: "john@@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: organization, role: role)
    expect(user).not_to be_valid
  end
end

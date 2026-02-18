require 'rails_helper'

RSpec.describe "Users API", type: :request do
  before do
    @organization = Organization.create!(name: "Test Org", description: "Test Organization")
    @role_user = Role.create!(name: "ORG_USER")
    @role_admin = Role.create!(name: "ORG_ADMIN")

    @admin_user = User.create!(
      full_name: "Admin User",
      email: "admin@example.com",
      phone: "9999999999",
      status: "active",
      password: "Password@123",
      organization: @organization,
      role: @role_admin
    )

    @token = JsonWebToken.encode(user_id: @admin_user.id, jti: @admin_user.jti, organization_id: @admin_user.organization_id)
    @headers = { "Authorization" => "Bearer #{@token}" }
  end

  describe "GET /users" do
    it "returns all users" do
      User.create!(full_name: "Alice", email: "alice@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: @organization, role: @role_user)
      User.create!(full_name: "Bob", email: "bob@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: @organization, role: @role_user)
      get "/users", headers: @headers
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /users/:id" do
    it "returns all users" do
      request.headers.merge!(@headers)
      user = User.create!(full_name: "Alice", email: "alice@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: @organization, role: @role_user)
      get "/users/#{user.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /users" do
    it "returns all users" do
      post "/users", headers: @headers, params: { full_name: "Alice", email: "alice@example.com", phone: "1234567890", status: "active", password: "Password@123", organization_id: @organization.id, role_id: @role_user.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /users/:id" do
    it "returns all users" do
      user = User.create!(full_name: "Alice", email: "alice@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: @organization, role: @role_user)
      put "/users/#{user.id}", headers: @headers, params: { full_name: "Alice updated" }
      puts response.body
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /users/:id" do
    it "returns all users" do
      user = User.create!(full_name: "Alice", email: "alice@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: @organization, role: @role_user)
      delete "/users/#{user.id}", headers: @headers
      expect(response).to have_http_status(:success)
    end
  end
end

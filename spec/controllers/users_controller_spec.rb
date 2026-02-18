require 'rails_helper'

RSpec.describe UsersController, type: :controller do
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
    ActionMailer::Base.deliveries.clear
  end
  describe "GET #index" do
    it "returns a successful response" do
      request.headers.merge!(@headers)
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show/:id" do
    it "returns a successful response" do
      request.headers.merge!(@headers)
      user = User.create!(full_name: "Alice", email: "alice@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: @organization, role: @role_user)
      get :show, params: { id: user.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    it "returns a successful response" do
      request.headers.merge!(@headers)
      post :create, params: { full_name: "Alice", email: "alice@example.com", phone: "1234567890", status: "active", password: "Password@123", organization_id: @organization.id, role_id: @role_user.id }
      expect(response).to have_http_status(:created)
    end
  end

  describe "PUT #update" do
    it "returns a successful response" do
      request.headers.merge!(@headers)
      user = User.create!(full_name: "Alice", email: "alice@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: @organization, role: @role_user)
      put :update, params: { id: user.id, full_name: "Alice updated" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE #destroy" do
    it "returns a successful response" do
      request.headers.merge!(@headers)
      user = User.create!(full_name: "Alice", email: "alice@example.com", phone: "1234567890", status: "active", password: "Password@123", organization: @organization, role: @role_user)
      delete :destroy, params: { id: user.id }
      expect(response).to have_http_status(:success)
    end
  end
end

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Test Org")

    @admin_role = Role.create!(name: ENV["ORG_ADMIN_ROLE"] || "ORG_ADMIN")
    @user_role  = Role.create!(name: ENV["ORG_USER_ROLE"]  || "ORG_USER")

    @admin = User.create!(
      full_name: "Admin User",
      email: "admin@test.com",
      password: "Password@123",
      role: @admin_role,
      organization: @organization,
      status: "ACTIVE",
      jti: SecureRandom.uuid
    )

    @user = User.create!(
      full_name: "Test User",
      email: "user@test.com",
      password: "Password@123",
      role: @user_role,
      organization: @organization,
      status: "ACTIVE"
    )

    @headers = {
      "Authorization" => "Bearer #{generate_token(@admin)}",
      "Content-Type" => "application/json"
    }
  end

  test "should get users index" do
    get users_url, headers: @headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json.length
  end

  test "should show user" do
    get user_url(@user), headers: @headers
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post users_url,
           params: {
             full_name: "New User",
             email: "newuser@test.com",
             phone: "9999999999"
           }.to_json,
           headers: @headers
    end

    assert_response :created
  end

  test "should update user" do
    patch user_url(@user),
          params: { full_name: "Updated Name" }.to_json,
          headers: @headers

    assert_response :success
    @user.reload
    assert_equal "Updated Name", @user.full_name
  end

  test "should soft delete user" do
    delete user_url(@user), headers: @headers
    assert_response :ok

    @user.reload
    assert @user.deleted?
  end

  test "should restore user" do
    @user.destroy

    patch restore_user_url(@user), headers: @headers
    assert_response :ok

    @user.reload
    assert_not @user.deleted?

  test "should not allow cross organization access" do
    other_org = Organization.create!(name: "Other Org")
    other_user = User.create!(
      full_name: "Other",
      email: "other@test.com",
      password: "Password@123",
      role: @user_role,
      organization: other_org,
      status: "ACTIVE"
    )

    get user_url(other_user), headers: @headers
    assert_response :not_found
  end
  end
end

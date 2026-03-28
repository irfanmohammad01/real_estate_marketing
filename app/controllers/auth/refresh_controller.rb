class Auth::RefreshController < ApplicationController
  skip_before_action :authorize_request

  def create
    token = cookies.encrypted[:refresh_token]

    unless token
      render json: { error: "No refresh token provided" }, status: :unauthorized
      return
    end

    begin
      decoded = JsonWebToken.decode(token)
    rescue AuthenticationError => e
      render json: { error: e.message }, status: :unauthorized
      return
    end

    unless decoded
      render json: { error: "Invalid refresh token" }, status: :unauthorized
      return
    end

    if decoded[:super_user_id]
      user = SuperUser.find_by(id: decoded[:super_user_id])
      is_super_user = true
    elsif decoded[:user_id]
      user = User.includes(:role).find_by(id: decoded[:user_id])
      is_super_user = false
    end

    if user.nil? || user.jti != decoded[:jti]
      render json: { error: "Token revoked or user not found" }, status: :unauthorized
      return
    end

    if is_super_user
      access_token = JsonWebToken.encode(
        super_user_id: user.id,
        jti: user.jti
      )
    else
      access_token = JsonWebToken.encode(
        user_id: user.id,
        role: user.role.name,
        organization_id: user.organization_id,
        jti: user.jti
      )
    end

    cookies.encrypted[:access_token] = {
      value: access_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      expires: 15.minutes.from_now
    }

    render json: { message: "Token refreshed successfully" }, status: :ok
  end
end

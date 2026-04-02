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

    unless decoded && decoded[:session_id] && decoded[:jti]
      render json: { error: "Invalid refresh token structure" }, status: :unauthorized
      return
    end

    session = RefreshToken.find_by(id: decoded[:session_id])

    if session.nil?
      render json: { error: "Session revoked" }, status: :unauthorized
      return
    end

    if session.token != decoded[:jti]
      session.destroy!
      render json: { error: "Token reuse detected. Session revoked." }, status: :unauthorized
      return
    end

    if session.expires_at && session.expires_at < Time.current
      session.destroy!
      render json: { error: "Session expired" }, status: :unauthorized
      return
    end

    user = session.authenticatable

    if user.nil?
      render json: { error: "User not found" }, status: :unauthorized
      return
    end

    session.update!(token: SecureRandom.uuid, expires_at: 7.days.from_now)

    if session.authenticatable_type == "SuperUser"
      access_token = JsonWebToken.encode(
        super_user_id: user.id,
        jti: session.token,
        session_id: session.id
      )
      refresh_token = JsonWebToken.encode(
        { super_user_id: user.id, jti: session.token, session_id: session.id },
        7.days.from_now.to_i
      )
    else
      access_token = JsonWebToken.encode(
        user_id: user.id,
        role: user.role.name,
        organization_id: user.organization_id,
        jti: session.token,
        session_id: session.id
      )
      refresh_token = JsonWebToken.encode(
        { user_id: user.id, jti: session.token, session_id: session.id },
        7.days.from_now.to_i
      )
    end

    cookies.encrypted[:access_token] = {
      value: access_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      expires: 15.minutes.from_now
    }

    cookies.encrypted[:refresh_token] = {
      value: refresh_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      expires: 7.days.from_now
    }

    render json: { message: "Token refreshed successfully" }, status: :ok
  end
end

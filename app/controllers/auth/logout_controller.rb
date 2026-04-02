class Auth::LogoutController < ApplicationController
  def destroy
    token = cookies.encrypted[:access_token] || cookies.encrypted[:refresh_token]
    
    if token
      decoded = JsonWebToken.decode(token) rescue nil
      if decoded && decoded[:session_id]
        RefreshToken.find_by(id: decoded[:session_id])&.destroy
      end
    end

    cookies.delete(:access_token)
    cookies.delete(:refresh_token)

    render json: { message: "Logged out successfully" }, status: :ok
  rescue => e
    Rails.logger.error "Logout failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Logout failed", message: e.message }, status: :internal_server_error
  end
end

class Auth::LogoutController < ApplicationController
  def destroy
    if @current_super_user
      @current_super_user.rotate_jti!
      render json: { message: "Logged out successfully" }, status: :ok
    elsif @current_user
      @current_user.rotate_jti!
      render json: { message: "Logged out successfully" }, status: :ok
    else
      render json: { error: "No active session found" }, status: :unauthorized
    end
  rescue => e
    Rails.logger.error "Logout failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Logout failed", message: e.message }, status: :internal_server_error
  end
end

class Auth::LogoutController < ApplicationController
  def destroy
    if @current_user
      render json: { message: "Logged out successfully" }, status: :ok
    else
      render json: { error: "No active session found" }, status: :unauthorized
    end
  end
end

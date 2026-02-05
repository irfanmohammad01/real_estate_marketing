class Auth::UsersController < ApplicationController
  skip_before_action :authenticate_request, only: [:login]

  def login
    user = User.includes(:role).find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(
        user_id: user.id,
        role: user.role.name,
        organization_id: user.organization_id
      )

      render json: {
        token: token,
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          role: user.role.name,
          organization_id: user.organization_id
        }
      }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end
end

class Auth::SessionsController < ApplicationController
  skip_before_action :authorize_request, only: [ :create ]
  rate_limit(**DEFAULT_RATE_LIMIT, only: [ :create ])

  def create
    user = User.includes(:role, :organization).find_by(email: session_params[:email])

    if user&.authenticate(session_params[:password])
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
          organization_id: user.organization_id,
          organization_name: user.organization.name
        }
      }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  private

  def session_params
    params.permit(:email, :password)
  end
end

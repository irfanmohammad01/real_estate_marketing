class Auth::UsersController < ApplicationController
  skip_before_action :authorize_request, only: [ :login ]
  rate_limit(**DEFAULT_RATE_LIMIT, only: [ :login ])

  def login
    user = User.includes(:role).find_by(email: user_params[:email])

    if user&.authenticate(user_params[:password])
      token = JsonWebToken.encode(
        user_id: user.id,
        role: user.role.name,
        organization_id: user.organization_id,
        jti: user.jti
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

  private
  def user_params
    params.permit(:email, :password)
  end
end

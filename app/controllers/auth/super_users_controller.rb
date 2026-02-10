class Auth::SuperUsersController < ApplicationController
  skip_before_action :authorize_request, only: [ :login ]
  rate_limit(**DEFAULT_RATE_LIMIT, only: [ :login ])

  def login
    user = User.joins(:role)
               .find_by(email: params[:email], roles: { name: Role::ROLES[:superuser] })

    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id)

      render json: {
        token: token,
        user: {
          id: user.id,
          email: user.email,
          role: user.role.name
        }
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end
end

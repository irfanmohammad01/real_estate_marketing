class Auth::SuperUsersController < ApplicationController
  skip_before_action :authorize_request, only: [ :login ]
  rate_limit(**DEFAULT_RATE_LIMIT, only: [ :login ])

  def login
    super_user = SuperUser.find_by(email: params[:email])

    if super_user&.authenticate(params[:password])
      token = JsonWebToken.encode(
        super_user_id: super_user.id,
        jti: super_user.jti
      )

      render json: {
        token: token,
        super_user: {
          id: super_user.id,
          email: super_user.email
        }
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end
end

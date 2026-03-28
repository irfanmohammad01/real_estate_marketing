class Auth::SuperUsersController < ApplicationController
  skip_before_action :authorize_request, only: [ :login ]
  rate_limit(**DEFAULT_RATE_LIMIT, only: [ :login ])

  def login
    super_user = SuperUser.find_by(email: params[:email])

    if super_user&.authenticate(params[:password])
      access_token = JsonWebToken.encode(
        super_user_id: super_user.id,
        jti: super_user.jti
      )

      refresh_token = JsonWebToken.encode(
        { super_user_id: super_user.id, jti: super_user.jti },
        7.days.from_now.to_i
      )

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

      render json: {
        message: "Logged in successfully",
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

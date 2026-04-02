class Auth::UsersController < ApplicationController
  skip_before_action :authorize_request, only: [ :login ]
  rate_limit(**DEFAULT_RATE_LIMIT, only: [ :login ])

  def login
    user = User.includes(:role).find_by(email: user_params[:email])
    if user&.authenticate(user_params[:password])
      session = user.refresh_tokens.create!(
        token: SecureRandom.uuid,
        expires_at: 7.days.from_now
      )

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
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          role: user.role.name,
          organization_id: user.organization_id,
          organization_name: Organization.find(user.organization_id).name
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

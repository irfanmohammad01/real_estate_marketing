class Auth::SuperUsersController < ApplicationController
  def login
    super_user = SuperUser.find_by(email: params[:email])

    if super_user&.authenticate(params[:password])
      token = JsonWebToken.encode(super_user_id: super_user.id)

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

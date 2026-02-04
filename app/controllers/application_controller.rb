class ApplicationController < ActionController::API
  before_action :authorize_request

  private

  def authorize_request
    header = request.headers['Authorization']
    token = header&.split(' ')&.last

    decoded = JsonWebToken.decode(token)
    @current_super_user = SuperUser.find_by(id: decoded[:super_user_id]) if decoded
  end

  def authorize_super_user!
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_super_user
  end
  
end
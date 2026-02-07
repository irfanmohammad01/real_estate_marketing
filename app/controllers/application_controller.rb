class ApplicationController < ActionController::API
  before_action :authorize_request
  attr_reader :current_super_user, :current_user

  private

  def authorize_request
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last

    unless token
      render json: { error: "No token provided" }, status: :unauthorized
      return
    end

    decoded = JsonWebToken.decode(token)

    unless decoded
      render json: { error: "Invalid token" }, status: :unauthorized
      return
    end

    if decoded[:super_user_id]
      @current_super_user = SuperUser.find_by(id: decoded[:super_user_id])
    elsif decoded[:user_id]
      @current_user = User.find_by(id: decoded[:user_id])
    end

    unless @current_super_user || @current_user
      render json: { error: "User not found" }, status: :unauthorized
    end
  end

  def authorize_super_user!
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_super_user
  end

  def authorize_super_or_org_admin! 
    unless @current_super_user || org_admin? 
      render json: { error: "Not authorized" }, status: :forbidden 
    end 
  end

  def authorize_org_admin!
    unless org_admin?
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def org_admin?
    current_user&.role&.name == "ORG_ADMIN"
  end

  def org_user?
    current_user&.role&.name == "ORG_USER"
  end

  def authorize_org_member!(*roles)
    unless current_user && current_user.role && roles.include?(current_user.role.name)
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end
end

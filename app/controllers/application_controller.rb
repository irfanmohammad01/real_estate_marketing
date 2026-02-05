class ApplicationController < ActionController::API
  before_action :authorize_request
  attr_reader :current_super_user, :current_user

  private

  def authorize_request
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last
    decoded = JsonWebToken.decode(token)

    return unless decoded

    if decoded[:super_user_id]
      @current_super_user = SuperUser.find_by(id: decoded[:super_user_id])
    elsif decoded[:user_id]
      @current_user = User.find_by(id: decoded[:user_id])
    end
  end

  def authorize_super_user!
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_super_user
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


  # before_action -> { authorize_roles!("ORG_ADMIN", "ORG_USER") }
  def authorize_org_member!(*roles)
    unless current_user && roles.include?(current_user.role.name)
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end
end

class ApplicationController < ActionController::API
  rate_limit(**DEFAULT_RATE_LIMIT)
  before_action :authorize_request
  attr_reader :current_super_user, :current_user

  rescue_from AuthenticationError do |e|
    render json: { error: e.message }, status: :unauthorized
  end

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
    unless current_user&.org_admin?
      render_forbidden("ORG_ADMIN role required")
    end
  end

  def authorize_org_member!(*roles)
    unless current_user && roles.any? { |r| current_user.send("#{r}?") rescue false }
      render_forbidden("Insufficient permissions")
    end
  end
end

  private

  def render_forbidden(message)
    log_authorization_failure(message)
    render json: { error: message }, status: :forbidden
  end


  def log_authorization_failure(reason)
    Rails.logger.warn({
      event: "authorization_failure",
      user_id: current_user&.id,
      reason: reason,
      path: request.path,
      timestamp: Time.current
    }.to_json)
  end

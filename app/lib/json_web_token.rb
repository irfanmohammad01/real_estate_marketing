class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    raise ArgumentError, "JTI is required in payload" unless payload[:jti].present?

    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, "HS256")
  end


  def self.decode(token)
    begin
      body = JWT.decode(token, SECRET_KEY, true, { algorithm: ENV["JWT_ALGORITHM"] })[0]
      HashWithIndifferentAccess.new(body)
    rescue JWT::ExpiredSignature
      raise AuthenticationError, "Token has expired"
    rescue JWT::DecodeError => e
      raise AuthenticationError, "Invalid or malformed token"
    end
  end
end

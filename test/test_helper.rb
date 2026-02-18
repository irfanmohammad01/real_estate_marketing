ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module AuthHelper
  def auth_headers(user)
    token = generate_token(user)
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    def generate_token(user)
      payload = {
        user_id: user.id,
        jti: user.jti,
        exp: 24.hours.from_now.to_i
      }
      JWT.encode(payload, Rails.application.secret_key_base)
    end
  end
end

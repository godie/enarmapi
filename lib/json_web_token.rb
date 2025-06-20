# lib/json_web_token.rb
class JsonWebToken
  # SECRET_KEY = Rails.application.credentials.secret_key_base

  def self.secret_key
    # Fetch the currently configured secret_key_base for the environment
    Rails.application.secret_key_base
  end

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, secret_key)
  end

  def self.decode(token)
    body = JWT.decode(token, secret_key)[0]
    HashWithIndifferentAccess.new body
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end

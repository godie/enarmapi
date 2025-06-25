class AuthController < ApplicationController
  def auth_user
    login_value = params[:email].to_s.strip.downcase
    # busca por email o por username (case-insensitive)
    user = User.where("lower(email) = :v OR lower(username) = :v", v: login_value).first

    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: { token: token }, status: :ok
    else
      render json: { error: "Credenciales inválidas" }, status: :unauthorized
    end
  end

  def info
    info = {
      RAILS_ENV: Rails.env,
      DB_USER: ENV["DATABASE_USER"],
      PASS: ENV["DATABASE_PASSWORD"],
      HOST: ENV["DATABASE_HOST"]
    }
    render json: info, status: :ok
  end
end

class UsersController < ApplicationController
  before_action :authenticate_admin!, only: %i[index destroy]
  before_action :authenticate_user!, only: %i[show update stats contributions]
  before_action :set_user, only: %i[show update destroy]

  # GET /users
  def index
    @users = User.all
    render json: @users
  end

  # GET /users/1
  def show
    if @current_user.admin? || @user.id == @current_user.id
      render json: user_json(@user)
    else
      render json: { error: "No autorizado" }, status: :unauthorized
    end
  end

  # POST /users (Registro)
  def create
    @user = User.find_by(email: user_params[:email]) || User.new(user_params)

    if @user.persisted?
      render json: user_json(@user), status: :ok
    elsif @user.save
      render json: user_json(@user), status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1
  def update
    if @current_user.admin? || @user.id == @current_user.id
      if @user.update(user_params)
        render json: user_json(@user)
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    else
      render json: { error: "No autorizado" }, status: :unauthorized
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy!
  end

  # POST /login
  def login
    login_value = params[:email].to_s.strip.downcase
    user = User.find_by("lower(email) = ?", login_value) || User.find_by("lower(username) = ?", login_value)

    if user&.authenticate(params[:password])
      render json: user_json(user), status: :ok
    else
      render json: { error: "Credenciales inválidas" }, status: :unauthorized
    end
  end

  # GET /users/me/stats
  def stats
    render json: @current_user.stats.merge(total_points: @current_user.total_points)
  end

  # GET /users/me/contributions - clinical cases contributed by the current user
  def contributions
    cases = @current_user.clinical_cases.order(created_at: :desc)
    render json: { contributions: cases }
  end

  # POST /google_login
  def google_login
    social_login(provider: :google, provider_id_key: :google_id)
  end

  # POST /facebook_login
  def facebook_login
    social_login(provider: :facebook, provider_id_key: :facebook_id)
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Usuario no encontrado" }, status: :not_found
  end

  def user_params
    permitted = [ :username, :email, :password, :password_confirmation, :name, :facebook_id, :google_id, :preferences ]
    permitted << :role if @current_user&.admin?
    params.require(:user).permit(permitted)
  end

  def user_json(user)
    token = JsonWebToken.encode(user_id: user.id, player_id: user.id)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      username: user.username,
      role: user.role,
      preferences: user.preferences,
      token: token
    }
  end

  def social_login(provider:, provider_id_key:)
    provider_id = params[provider_id_key]
    email = params[:email]
    name = params[:name]

    user = User.find_by(provider_id_key => provider_id) || User.find_by(email: email)

    if user
      user.update(provider_id_key => provider_id) if user[provider_id_key].blank? && provider_id.present?
      render json: user_json(user), status: :ok
    else
      user_attributes = {
        email: email,
        name: name,
        role: :player,
        provider_id_key => provider_id
      }
      user = User.new(user_attributes)
      user.password = SecureRandom.hex(10)

      if user.save
        render json: user_json(user), status: :created
      else
        render json: user.errors, status: :unprocessable_entity
      end
    end
  end
end

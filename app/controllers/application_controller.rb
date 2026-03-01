class ApplicationController < ActionController::API
  include SetCurrentRequestDetails

  rescue_from ActionController::ParameterMissing do |exception|
    render json: { error: exception.message }, status: :bad_request
  end

  def authenticate_user!
    token = decoded_token
    user_id = token[:user_id] || token[:player_id]
    Current.user = nil
    Current.user = User.find_by(id: user_id) if user_id
    @current_user = Current.user # Compatibilidad con controladores existentes
    render json: { error: "No autorizado" }, status: :unauthorized unless Current.user
  end

  # Alias para compatibilidad con el frontend si es necesario
  def authenticate_player!
    authenticate_user!
    @current_player = @current_user
  end

  def authenticate_admin!
    authenticate_user!
    return if performed?

    unless Current.user.admin?
      render json: { error: "Acceso restringido a administradores" }, status: :forbidden
    end
  end

  # Ahora este método es redundante pero lo mantenemos por compatibilidad
  def authenticate_admin_or_player!
    authenticate_user!
  end

  private

  def decoded_token
    header = request.headers["Authorization"]
    header = header.split(" ").last if header
    JsonWebToken.decode(header) || {}
  rescue
    {}
  end
end

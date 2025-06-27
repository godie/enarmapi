# frozen_string_literal: true

module Players
  class AchievementsController < ApplicationController
    before_action :set_player

    # GET /players/:player_id/achievements
    def index
      @achievements = @player.achievements.includes(:player_achievements)

      render json: @achievements.as_json(
        except: [ :created_at, :updated_at, :criteria ], # Excluir criteria del logro base
        include: {
          player_achievements: {
            only: [ :achieved_at, :progress ] # Solo mostrar cuándo se logró y el progreso
            # Asegurarse de que solo se incluya el player_achievement del jugador actual
            # Esto se maneja por la consulta @player.achievements que ya filtra por el jugador.
          }
        }
      ).map do |achievement_json|
        # Como player_achievements es una colección (aunque aquí debería ser una por jugador/logro),
        # tomamos el primero. La relación @player.achievements ya asegura que estos PlayerAchievement
        # pertenecen al @player.
        player_achievement_info = achievement_json.delete("player_achievements").first
        if player_achievement_info
          achievement_json["achieved_at"] = player_achievement_info["achieved_at"]
          achievement_json["progress"] = player_achievement_info["progress"]
        end
        achievement_json
      end
    end

    private

    def set_player
      @player = Player.find_by(id: params[:player_id])
      render json: { error: "Player not found" }, status: :not_found unless @player
    end
  end
end

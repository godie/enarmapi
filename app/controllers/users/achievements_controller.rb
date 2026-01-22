# frozen_string_literal: true

module Users
  class AchievementsController < ApplicationController
    before_action :set_user

    # GET /users/:user_id/achievements
    def index
      @achievements = @user.achievements.includes(:user_achievements)

      render json: @achievements.as_json(
        except: [ :created_at, :updated_at, :criteria ],
        include: {
          user_achievements: {
            only: [ :achieved_at, :progress ]
          }
        }
      ).map do |achievement_json|
        user_achievement_info = achievement_json.delete("user_achievements").first
        if user_achievement_info
          achievement_json["achieved_at"] = user_achievement_info["achieved_at"]
          achievement_json["progress"] = user_achievement_info["progress"]
        end
        achievement_json
      end
    end

    private

    def set_user
      # Support both user_id (from /users/:user_id/achievements) and player_id (from /players/:player_id/achievements)
      user_id = params[:user_id] || params[:player_id]
      # Try to find by ID first, then by facebook_id if it's not numeric
      if user_id.to_s.match?(/^\d+$/)
        @user = User.find(user_id)
      else
        @user = User.find_by(facebook_id: user_id)
      end
      raise ActiveRecord::RecordNotFound unless @user
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Usuario no encontrado" }, status: :not_found
    end
  end
end

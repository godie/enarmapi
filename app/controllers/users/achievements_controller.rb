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
      @user = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Usuario no encontrado" }, status: :not_found
    end
  end
end

# frozen_string_literal: true

class AchievementsController < ApplicationController
  before_action :authenticate_admin!, only: [ :create, :update, :destroy ]
  before_action :set_achievement, only: [ :update, :destroy ]

  # GET /achievements
  def index
    @achievements = Achievement.all
    render json: @achievements.as_json(except: [ :created_at, :updated_at ])
  end

  # POST /achievements (solo admin)
  def create
    @achievement = Achievement.new(achievement_params)
    if @achievement.save
      render json: @achievement.as_json(except: [ :created_at, :updated_at ]), status: :created
    else
      render json: { errors: @achievement.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /achievements/:id (solo admin)
  def update
    if @achievement.update(achievement_params)
      render json: @achievement.as_json(except: [ :created_at, :updated_at ])
    else
      render json: { errors: @achievement.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /achievements/:id (solo admin)
  def destroy
    @achievement.destroy
    head :no_content
  end

  private

  def set_achievement
    @achievement = Achievement.find(params[:id])
  end

  def achievement_params
    params.require(:achievement).permit(:name, :description, :icon_url, :points, criteria: {})
  end
end

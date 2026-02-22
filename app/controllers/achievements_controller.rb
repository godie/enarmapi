# frozen_string_literal: true

class AchievementsController < ApplicationController
  # GET /achievements
  def index
    @achievements = Achievement.all
    render json: @achievements.as_json(except: [ :created_at, :updated_at ])
  end
end

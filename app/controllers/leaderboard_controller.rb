class LeaderboardController < ApplicationController
  # GET /leaderboard
  def index
    # Rank users by total achievement points
    @top_users = User.joins(:achievements)
                     .group(:id)
                     .select("users.id, users.name, users.username, SUM(achievements.points) as total_points")
                     .order("total_points DESC")
                     .limit(10)

    render json: @top_users
  end
end

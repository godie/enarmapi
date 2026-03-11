class V2LeaderboardController < ApplicationController
  before_action :authenticate_user!

  def national
    # En un entorno real, esto podría estar cacheado o usar una tabla de rankings
    # Para esta implementación, calculamos on-the-fly ordenando por total_points

    users_with_points = User.all.sort_by(&:total_points).reverse

    top_players = users_with_points.take(100).each_with_index.map do |user, index|
      {
        rank: index + 1,
        nickname: user.username || user.name || "DoctorX",
        points: user.total_points,
        avatar: "https://via.placeholder.com/150"
      }
    end

    current_user_rank = users_with_points.index(Current.user) + 1 rescue nil

    render json: {
      currentUser: {
        rank: current_user_rank,
        points: Current.user.total_points,
        avatar: "https://via.placeholder.com/150",
        nickname: Current.user.username || Current.user.name || "DoctorX"
      },
      topPlayers: top_players
    }
  end
end

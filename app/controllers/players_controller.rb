class PlayersController < ApplicationController
  before_action :set_player, only: %i[ show update destroy create ]

  # GET /players
  def index
    @players = Player.all

    render json: @players
  end

  # GET /players/1
  def show
    render json: player_json(@player)
  end

  # POST /players
  def create
    return render json: player_json(@player), status: :ok, location: @player if @player
    @player = Player.new(player_params)

    if @player.save
      render json: { player: player_json(@player) }, status: :created, location: @player
    else
      render json: @player.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /players/1
  def update
    if @player.update(player_params)
      render json: player_json(@player)
    else
      render json: @player.errors, status: :unprocessable_entity
    end
  end

  # DELETE /players/1
  def destroy
    @player.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find_by(facebook_id: player_params[:facebook_id])
    end

    # Only allow a list of trusted parameters through.
    def player_params
      params.require(:player).permit(:email, :facebook_id, :name)
    end

    def player_json(player)
        {
          id: player.id,
          facebook_id: player.facebook_id,
          name: player.name,
          email: player.email
        }
      end
end

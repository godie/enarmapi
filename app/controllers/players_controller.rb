class PlayersController < ApplicationController
  before_action :set_player_for_standard_actions, only: %i[ show update destroy ]
  before_action :find_or_initialize_player_for_create, only: %i[ create ]

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
    # If @player is found by find_or_initialize_player_for_create and it's persisted, it means it already exists.
    if @player.persisted?
      return render json: player_json(@player), status: :ok, location: @player
    end
    # If not persisted, it means it's a new record initialized with player_params
    # or found by facebook_id but not yet saved (if logic changes).
    # For now, assume find_or_initialize_player_for_create sets up @player as new or found.
    # If it's new, player_params were already used by find_or_initialize_player_for_create.
    # If it was found by facebook_id (and not persisted, which is unlikely with current find_or_initialize),
    # then we might need to assign params again if it was just `new`.
    # Let's simplify: find_or_initialize_player_for_create will set @player.
    # If it's a new record, then we save. If existing, we return.

    # Re-evaluating: The original create had `return ... if @player` (from the old set_player).
    # And then `Player.new(player_params)`.
    # This means if set_player found one by facebook_id, it returned it. Otherwise, create proceeded.

    # With find_or_initialize_player_for_create:
    # @player will be an existing record if facebook_id matched, or a new one if not.
    # If it's new, it needs saving. If existing, we should return it.

    if @player.new_record? && @player.save
      render json: { player: player_json(@player) }, status: :created, location: @player
    elsif !@player.new_record? # Already exists
      render json: player_json(@player), status: :ok, location: @player # Or :conflict if that's preferred
    else # New record, but save failed
      render json: @player.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /players/1
  def update
    if @player.update(player_params)
      render json: player_json(@player), status: :ok # Corrected status
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
    def set_player_for_standard_actions
      @player = Player.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Player not found by ID" }, status: :not_found
    end

    def find_or_initialize_player_for_create
      # Try to find by facebook_id first. If present, it's effectively an update/show.
      # If not, initialize a new one.
      if params[:player][:facebook_id].present?
        @player = Player.find_by(facebook_id: params[:player][:facebook_id])
      end
      @player ||= Player.new(player_params) # Initialize if not found by facebook_id
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

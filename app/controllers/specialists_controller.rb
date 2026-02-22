class SpecialistsController < ApplicationController
  before_action :authenticate_user!

  # GET /specialists
  def index
    @specialists = User.specialist.joins(:specialist_profile).where(specialist_profiles: { is_verified: true })
    render json: @specialists.as_json(include: :specialist_profile)
  end

  # GET /specialists/:id
  def show
    @specialist = User.specialist.find(params[:id])
    render json: @specialist.as_json(include: :specialist_profile)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Specialist not found" }, status: :not_found
  end
end

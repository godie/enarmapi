class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ update show ]

  # GET /categories
  def index
    @categories = Category.all
    render json: @categories, status: :ok
  end

  # POST /categories
  def create
    @category = Category.new(category_params)
    if @category.save
     render json: @category, status: :created, location: @category
    else
      render json: @category.errors, status: :unprocessable_entity
    end

  end

  # GET /categories/1
  def show
    render json: category_json(@category)
  end

  # PATCH/PUT /categories/1
  def update
     if @category.update(category_params)
      render json: @category, status: :ok, location: @category
    else
      render json: @category.errors, status: :unprocessable_entity
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
      params.require(:category).permit(:name, :description)
  end

  def category_json(category)
        {
          id: category.id,
          name: category.name,
          description: category.description
        }
      end


end

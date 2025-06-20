class ClinicalCasesController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_clinical_case, only: %i[ show update destroy ]
  # before_action :authenticate_request
  def index
    page = params[:page]
    @cases = ClinicalCase.paginate(page: page).order(id: :desc)
    render json: { current_page: @cases.current_page, per_page: @cases.per_page, total_entries: @cases.total_entries, clinical_cases: @cases }
  end

  def show
    render json: @clinical_case, include: { questions: { include: :answers } }
  end

  def create
    @clinical_case = ClinicalCase.new(clinical_case_params)
    if @clinical_case.save
      render json: @clinical_case, status: :created, location: @clinical_case, include: { questions: { include: :answers } }
    else
      render json: @clinical_case.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @clinical_case.destroy
    head :no_content # Or any other appropriate response
  end

  def update
    if @clinical_case.update(clinical_case_params)
      render json: @clinical_case, include: { questions: { include: :answers } }
    else
      render json: @clinical_case.errors, status: :unprocessable_entity
    end
  end

  private
  def set_clinical_case
    @clinical_case = ClinicalCase.find(params[:id])
  end

  def clinical_case_params
    params.require(:clinical_case).permit(
      :name, # Changed from title to name
      :description,
      :category_id,
      questions_attributes: [
        :id,
        :_destroy,
        :text,
        # :explanation, # Removed as it's not an attribute of Question
        # :points,      # Removed as it's not an attribute of Question
        answers_attributes: [
          :id,
          :_destroy,
          :text,
          :is_correct,
          :description
        ]
      ]
    )
  end
end

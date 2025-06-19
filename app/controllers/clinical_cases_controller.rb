class ClinicalCasesController < ApplicationController
  before_action :set_clinical_case, only: %i[ show update destroy ]
  #before_action :authenticate_request
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
      render json: @clinical_case, status: :created, location: @clinical_case
    else
      render json: @clinical_case.errors, status: :unprocessable_entity
    end
  end

  def destroy
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
      :description, # u otros atributos de ClinicalCase
      :category_id,
      questions_attributes: [
        :id, # Importante para actualizar preguntas existentes
        :_destroy, # Para eliminar preguntas
        :text, # u otros atributos de Question
        answers_attributes: [
          :id, # Importante para actualizar respuestas existentes
          :_destroy, # Para eliminar respuestas
          :text, :is_correct, :description # u otros atributos de Answer
        ]
      ]
    )
  end
end

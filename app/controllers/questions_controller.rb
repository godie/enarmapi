class QuestionsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_clinical_case
  before_action :set_question, only: [:show, :update, :destroy]

  # GET /clinical_cases/:clinical_case_id/questions
  def index
    @questions = @clinical_case.questions
    render json: @questions, include: [:answers]
  end

  # GET /clinical_cases/:clinical_case_id/questions/:id
  def show
    render json: @question, include: [:answers]
  end

  # POST /clinical_cases/:clinical_case_id/questions
  def create
    @question = @clinical_case.questions.new(question_params)

    if @question.save
      render json: @question, status: :created, location: clinical_case_question_url(@clinical_case, @question)
    else
      render json: @question.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /clinical_cases/:clinical_case_id/questions/:id
  def update
    if @question.update(question_params)
      render json: @question
    else
      render json: @question.errors, status: :unprocessable_entity
    end
  end

  # DELETE /clinical_cases/:clinical_case_id/questions/:id
  def destroy
    @question.destroy
    head :no_content
  end

  private

  def set_clinical_case
    @clinical_case = ClinicalCase.find(params[:clinical_case_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "ClinicalCase not found" }, status: :not_found
  end

  def set_question
    @question = @clinical_case.questions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Question not found" }, status: :not_found
  end

  def question_params
    params.require(:question).permit(
      :text,
      :explanation,
      :points,
      answers_attributes: [
        :id,
        :_destroy,
        :text,
        :is_correct,
        :description
      ]
    )
  end
end

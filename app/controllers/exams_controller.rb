class ExamsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_exam, only: [ :show, :update, :destroy ]

  # GET /exams
  def index
    @exams = Exam.all
    render json: @exams, include: { exam_questions: { include: :question } }
  end

  # GET /exams/1
  def show
    render json: @exam, include: { exam_questions: { include: :question } }
  end

  # POST /exams
  def create
    @exam = Exam.new(exam_params)

    if @exam.save
      render json: @exam, status: :created, location: @exam, include: { exam_questions: { include: :question } }
    else
      render json: @exam.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /exams/1
  def update
    if @exam.update(exam_params)
      render json: @exam, include: { exam_questions: { include: :question } }
    else
      render json: @exam.errors, status: :unprocessable_entity
    end
  end

  # DELETE /exams/1
  def destroy
    @exam.destroy
    head :no_content
  end

  private

  def set_exam
    @exam = Exam.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Exam not found" }, status: :not_found
  end

  def exam_params
    params.require(:exam).permit(
      :name,
      :description,
      :available_from,
      :available_to,
      exam_questions_attributes: [
        :id,
        :question_id,
        :points,
        :position,
        :_destroy # Allows removing exam_questions records
      ]
    )
  end
end

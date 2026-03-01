class QuestionsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_question, only: [ :show, :update, :destroy ]

  # GET /questions
  # GET /questions?clinical_case_id=:clinical_case_id
  # GET /questions?category_id=:category_id
  def index
    if params[:clinical_case_id]
      @clinical_case = ClinicalCase.find_by(id: params[:clinical_case_id])
      if @clinical_case
        @questions = @clinical_case.questions
      else
        return render json: { error: "ClinicalCase not found" }, status: :not_found
      end
    elsif params[:category_id]
      @category = Category.find_by(id: params[:category_id])
      if @category
        # Use the scope defined in Question model
        @questions = Question.by_category(params[:category_id])
      else
        return render json: { error: "Category not found" }, status: :not_found
      end
    else
      # Consider pagination for listing all questions
      @questions = Question.all.order(id: :desc)
    end
    @questions = @questions.paginate(page: params[:page]).includes(:answers, :category, :clinical_case)
    render json: { current_page: @questions.current_page, per_page: @questions.per_page, total_entries: @questions.total_entries, questions: @questions }, include: [ :answers, :category, :clinical_case ]
  end

  # GET /questions/:id
  def show
    render json: @question, include: [ :answers, :category, :clinical_case ]
  end

  # POST /questions
  def create
    # ClinicalCase association is now optional, can also be associated directly with a category
    @question = Question.new(question_params)

    if @question.save
      render json: @question, status: :created, location: question_url(@question), include: [ :answers, :category, :clinical_case ]
    else
      render json: @question.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /questions/:id
  def update
    if @question.update(question_params)
      render json: @question, include: [ :answers, :category, :clinical_case ]
    else
      render json: @question.errors, status: :unprocessable_entity
    end
  end

  # DELETE /questions/:id
  def destroy
    @question.destroy
    head :no_content
  end

  private

  def set_question
    @question = Question.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Question not found" }, status: :not_found
  end

  def question_params
    params.require(:question).permit(
      :text,
      :clinical_case_id, # Added
      :category_id,      # Added
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

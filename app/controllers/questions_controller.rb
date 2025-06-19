class QuestionsController < ApplicationController
  def index
    @questions = Question.where(clinical_case_id: params[:clinical_case_id])
    render json: @questions, include: [ :answers, :clinical_case ]
  end
end

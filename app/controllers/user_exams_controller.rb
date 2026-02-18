class UserExamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_exam, only: [ :show, :update ]

  # GET /user_exams
  def index
    @user_exams = @current_user.user_exams.includes(:exam)
    render json: @user_exams, include: :exam
  end

  # GET /user_exams/1
  def show
    render json: @user_exam, include: {
      exam: {
        include: {
          exam_questions: {
            include: {
              question: {
                include: :answers
              }
            }
          }
        }
      },
      user_exam_answers: {}
    }
  end

  # POST /user_exams
  def create
    @exam = Exam.find(params[:exam_id])
    @user_exam = @current_user.user_exams.build(exam: @exam, status: "in_progress", started_at: Time.current)

    if @user_exam.save
      render json: @user_exam, status: :created
    else
      render json: @user_exam.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /user_exams/1
  def update
    if @user_exam.status == "completed"
      return render json: { error: "Este examen ya ha sido completado" }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      answers_params.each do |answer_param|
        exam_question = @user_exam.exam_questions.find(answer_param[:exam_question_id])
        answer = exam_question.question.answers.find(answer_param[:answer_id])

        points_earned = answer.is_correct? ? (exam_question.points || 1) : 0

        @user_exam.user_exam_answers.create!(
          exam_question: exam_question,
          answer: answer,
          is_correct: answer.is_correct?,
          points_earned: points_earned
        )
      end

      @user_exam.update!(
        status: "completed",
        completed_at: Time.current,
        score: @user_exam.calculate_score
      )
    end

    # Unlock achievements
    unlocked_achievements = Achievements::UnlockService.new(@current_user).call

    render json: {
      user_exam: @user_exam,
      score: @user_exam.score,
      unlocked_achievements: unlocked_achievements.map { |ach| { id: ach.id, name: ach.name } }
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue => e
    render json: { error: "Ocurrió un error al procesar el examen: #{e.message}" }, status: :internal_server_error
  end

  private

  def set_user_exam
    @user_exam = @current_user.user_exams.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Examen de usuario no encontrado" }, status: :not_found
  end

  def answers_params
    params.require(:answers).map do |answer_param|
      answer_param.permit(:exam_question_id, :answer_id)
    end
  end
end

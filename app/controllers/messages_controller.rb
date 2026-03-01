class MessagesController < ApplicationController
  before_action :authenticate_user!

  # GET /messages
  # List recent conversations
  def index
    # This is a bit complex for a simple query, but let's do a basic version
    sent_ids = Current.user.sent_messages.select(:receiver_id).distinct.pluck(:receiver_id)
    received_ids = Current.user.received_messages.select(:sender_id).distinct.pluck(:sender_id)
    user_ids = (sent_ids + received_ids).uniq

    @users = User.where(id: user_ids)
    render json: @users
  end

  # GET /messages/:user_id
  # History with a specific user
  def show
    @messages = Message.between(Current.user.id, params[:id]).order(created_at: :asc)
    # Mark as read
    @messages.where(receiver_id: Current.user.id, read_at: nil).update_all(read_at: Time.current)
    render json: @messages
  end

  # POST /messages
  def create
    @message = Current.user.sent_messages.build(message_params)
    if @message.save
      render json: @message, status: :created
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:receiver_id, :content)
  end
end

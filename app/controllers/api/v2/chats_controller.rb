class Api::V2::ChatsController < Api::V2::ApiController
   before_action :require_login
   
   #GET /chats
   def index
     @chats = Chat.all

     render json: @chats
   end
  
   #GET /chats/sender/:id
   def get_by_sender
     @chats = Chat.where(sender_id: params[:sender_id])

     render json: @chats
   end
  
   #GET /chats/receiver/:id
   def get_by_receiver
     @chats = Chat.where(receiver_id: params[:receiver_id])

     render json: @chats
   end
  
  #GET /chats/:id
  def show
    render json: @chat
  end
  
  #POST /chats
  def create
    @chat = Chat.new(chat_params)

    if @chat.save
      render json: @chat, status: :created
    else
      render json: @chat.errors, status: :unprocessable_entity
    end
    
  end
  
  # PATCH/PUT /chats/:id
  def update
    if @chat.update(chat_params)
      render json: @chat
    else
      render json: @chat.errors, status: :unprocessable_entity
    end
  end
  
  # DELETE /chats/:id
  def destroy
    @chat.destroy
  end
  
  private
    def chat_params
      params.require(:chat).permit(:message, :is_read, :sender_id, :receiver_id, :created_at, :updated_at, :order_id)
    end
  
end

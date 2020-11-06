class Api::V2::ChatsController < Api::V2::ApiController
   before_action :require_login
   before_action :set_chat, only: [:show, :update, :destroy]
   
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


   #GET /chats/order/:id
   def get_by_order
    @chats = Chat.where(order_id: params[:order_id])

    render json: @chats
  end
  
  #GET /chats/:id
  def show
    render json: @chat
  end
  
  #POST /chats
  def create
    @chat = Chat.new(chat_params)
    
    @sender = User.find(chat_params[:sender_id])
    @receiver = User.find(chat_params[:receiver_id])
    @order = Order.find(chat_params[:order_id])

    if (@sender == @receiver)
      render json: {"error": "Error: Sender can not be the same as receiver."}
      return
    end
    

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
    # Use callbacks to share common setup or constraints between actions.
    def set_chat
      @chat = Chat.find(params[:id])
    end

    def chat_params
      params.require(:chat).permit(:message, :is_read, :sender_id, :receiver_id, :created_at, :updated_at, :order_id)
    end
  
end

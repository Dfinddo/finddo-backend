class Api::V2::ChatsController < Api::V2::ApiController
   before_action :require_login
   before_action :set_chat, only: [:show]
   before_action :check_admin, only: [:index, :show]
   
   #GET /chats
   def index
     @chats = Chat.all

     render json: @chats
   end
  
   #GET /chats/sender/:id
   def get_by_sender
     @chats = Chat.where(sender_id: params[:sender_id])
     if (session_user.id != params[:sender_id].to_i && session_user.user_type != "admin")
      render json: {"error": "Error: Current user is not the sender or admin."}
      return 400
    end

     render json: @chats
   end
  
   #GET /chats/receiver/:id
   def get_by_receiver
     @chats = Chat.where(receiver_id: params[:receiver_id])

     if (session_user.id != params[:receiver_id].to_i && session_user.user_type != "admin")
      render json: {"error": "Error: Current user is not the sender or admin."}
      return 400
    end

     render json: @chats
   end


   #GET /chats/order/:id
   def get_by_order
    order = Order.find(params[:order_id].to_i)
    @chats = Chat.where(order_id: params[:order_id])

    chat_sample = @chats[0]    
    if ((session_user.id != chat_sample.sender_id && session_user.id != chat_sample.receiver_id) && session_user.user_type != "admin")
      #ver por que apenas nesse caso, caso o session_user seja o admin, continua caindo aqui.
      render json: {"error": "Current user doesn't have permission to acess this."}
      return 400
    end

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
    

    if (session_user != User.find(@chat.sender_id))
      render json: {"error": "Error: Current user is not the sender."}
      return 400
    end

    if (@sender == @receiver)
      render json: {"error": "Error: Sender can not be the receiver."}
      return 400
    end
    
    if @chat.save
      render json: @chat, status: :created
    else
      render json: @chat.errors, status: :unprocessable_entity
    end
    
  end
  
  # PATCH/PUT /chats/:id
  #def update
  # Only sender can update chat, not even admin.
  #  if (session_user != User.find(params[:sender_id]))
  #    render json: {"error": "Error: Current user is not the sender."}
  #    return 400
  #  end

  #  if @chat.update(chat_params)
  #    render json: @chat
  #  else
  #    render json: @chat.errors, status: :unprocessable_entity
  #  end
  
  #end
  
  # DELETE /chats/:id
  #def destroy
  #   Only sender can delete chat, not even admin.
  #  if (session_user != User.find(@chat.sender_id))
  #    render json: {"error": "Error: Current user is not the sender."}
  #    return 400
  #  end

  #  @chat.destroy
  #end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chat
      @chat = Chat.find(params[:id])
    end

    def chat_params
      params.require(:chat).permit(:message, :is_read, :sender_id, :receiver_id, :created_at, :updated_at, :order_id)
    end

    def check_user_receiver
      #Not in use, but coded, in case its needed.
      if (session_user != User.find(@chat.receiver_id) && session_user.user_type != "admin")
        render json: {"error": "Error: Current user is not the receiver."}
        return 400
      end

      return 0
    end

    def check_user_sender
      if (session_user != User.find(@chat.sender_id) && session_user.user_type != "admin")
        render json: {"error": "Error: Current user is not the sender."}
        return 400
      end

      return 0
    end

    def check_admin
      if (session_user.user_type == "admin")
        return 0
      end

      render json: {"error": "Error: Admin privileges required."}
      return 400
    end
  
end

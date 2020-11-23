class Api::V2::ChatsController < Api::V2::ApiController
   before_action :require_login
   before_action :set_chat, only: [:show]
   before_action :check_admin, only: [:index, :show]
   
   #GET /chats?page
   def index
     page = params[:page].to_i

     if page == 0
      page = 1

     elsif page < 0
      render json: {"error": "Error: page is lesser then 1."}
      return 400

    end

     chats = Chat.all
     .order(created_at: :desc).page(page)

     total = chats.total_pages
    
    if ((total > 0) && (page > total) )
      render json: {"error": "Error: page is greater then total_pages."}
      return 400
    end

     render json: {"chats": chats, current_page: chats.current_page, total_pages: total}
   end
  
   #GET /chats/order/?page&order_id
   def get_by_order
    page = params[:page].to_i

    if page == 0
      page = 1
    elsif page < 0
      render json: {"error": "Error: page is lesser then 1."}
      return 400
    end
  
    order = Order.find(params[:order_id].to_i)
    chats = Chat.where(order_id: params[:order_id])
    .where(for_admin: 0)
    .order(created_at: :desc).page(page)
    
    total_pages = chats.total_pages

    if total_pages == 0
      render json: {"error": "Error: required order doesn't have any chats associated with it."}
      return 400
    elsif page > total_pages
      render json: {"error": "Error: page is greater then total_pages."}
      return 400
    end

    chat_sample = chats[0]
    if ((session_user.id != chat_sample.sender_id && session_user.id != chat_sample.receiver_id) && session_user.user_type != "admin")
      render json: {"error": "Current user doesn't have permission to acess this."}
      return 400
    end
    
    if (session_user.user_type != "admin" && (order.order_status == "finalizado" || order.order_status == "cancelado" || order.order_status == "analise"))
      response = {"chats": [], "current_page": 1, "total_pages": 1}
    else
      response = { chats: chats.map { |chat| ChatSerializer.new(chat) }, current_page: chats.current_page, total_pages: chats.total_pages }
    end

    render json: response
    return 200
   end

   #GET /chats/admin/order/?order_id&receiver_id&page
   def admin_chat_from_order
    page = params[:page].to_i

    if page == 0
      page = 1
    elsif page < 0
      render json: {"error": "Error: page is lesser then 1."}
      return 400
    end
    
    order_id = params[:order_id].to_i
    order = Order.find_by(id: order_id)

    if order == nil
      render json: {"error": "Error: Order does not exist."}
      return 400
    end

    receiver = User.find_by(id: params[:receiver_id].to_i)

    if session_user.user_type == "user" || session_user.user_type == "professional" 
      
      if receiver.user_type != "admin"
        render json: {"error": "Error: Receiver is not an admin."}
        return
      end
    
      service_type = order.category.name + " - "
      title = service_type + "Suporte" + " - " + receiver.name

      if session_user.user_type == "user"
        chats = Chat.where("sender_id = ? or sender_id = ?", session_user.id, receiver.id)
        .where(order_id: order_id)
        .where("receiver_id = ? or receiver_id = ?", session_user.id, receiver.id)
        .where(for_admin: 1)
        .order(created_at: :desc).page(page)

      elsif session_user.user_type == "professional"
        chats = Chat.where("sender_id = ? or sender_id = ?", session_user.id, receiver.id)
        .where(order_id: order_id)
        .where("receiver_id = ? or receiver_id = ?", session_user.id, receiver.id)
        .where(for_admin: 2)
        .order(created_at: :desc).page(page)

      end

    elsif session_user.user_type == "admin"

      service_type = order.category.name + " - " + receiver.name + " - "

      if receiver.user_type == "user"
        chats = Chat.where("sender_id = ? or sender_id = ?", session_user.id, receiver.id)
        .where(order_id: order_id)
        .where("receiver_id = ? or receiver_id = ?", session_user.id, receiver.id)
        .where(for_admin: 1)
        .order(created_at: :desc).page(page)
      
        title = service_type + "Suporte (Usuário)"

      elsif receiver.user_type == "professional"
        chats = Chat.where("sender_id = ? or sender_id = ?", session_user.id, receiver.id)
        .where(order_id: order_id)
        .where("receiver_id = ? or receiver_id = ?", session_user.id, receiver.id)
        .where(for_admin: 2)
        .order(created_at: :desc).page(page)
      
        title = service_type + "Suporte (Profissional)"

      end

    else
      render json: {"debug": "Error: This function logic is not prepared to deal with this type of user."}
      return 400

    end

    total = chats.total_pages
    if ((total > 0) && (page > total) )
      render json: {"error": "Error: page is greater then total_pages."}
      return 400
    end

    render json: {"chats": chats, current_page: chats.current_page, total_pages: total, title: title}

    return 200
   end

   #GET /chats/list?page
   def get_chat_list
     page = params[:page].to_i
     list = []

     if page == 0
       page = 1
     elsif page < 1
       render json: {"error": "Error: page is lesser then 1."}
       return 400
     end

     #Faz a chamada para funções de serviço de user
     user_services = ServicesModule::V2::UserService.new
    
     orders = Order.where("user_id = ? OR professional = ?", session_user.id, session_user.id)
     .where.not(order_status: :finalizado)
     .where.not(order_status: :cancelado)
     .where.not(order_status: :analise)
     .order(created_at: :desc).page(page)
    
     total = orders.total_pages

     if ((total > 0) && (page > total) )
       render json: {"error": "Error: page is greater then total_pages."}
       return 400
     end
    
     #Usuario não tem pedidos validos e ativos
     if orders == nil
       render json: {"error": "Error: Current user doesn't have any valid active orders."}
       return 400
     end

     for order in orders

       #Loop chegou ao fim, pois os pedidos validos acabaram
       if order == nil
         break
       end

       order_id = order.id
        
       last_chat = Chat.where(order_id: order_id)
       .where(for_admin: 0).last

       if session_user.user_type == "user"
        receiver_id = order.professional_order.id
      elsif session_user.user_type == "professional"
        receiver_id = order.user.id
      else
        render json: {"error": "Error: This function is intended for users and professionals only."}
        return 400
      end

       #Caso o determinado pedido ainda não tenha mensagens associadas a ele
       if last_chat == nil

         #Simula a forma que last_chat teria fora desta condicional
         last_chat = Chat.new({"receiver_id": receiver_id})

       end
        
       #Pega a foto do remetente
       receiver = User.find(receiver_id)
       receiver_profile_photo = user_services.get_profile_photo(receiver)
       
       if receiver_profile_photo != nil
         receiver_profile_photo = UserProfilePhotoSerializer.new(receiver_profile_photo)
       end 

       #Faz o título
       service_type = order.category.name + " - "
       title = service_type + receiver.name
      
       last_message = {"message": last_chat.message, "created_at": last_chat.created_at}

       list << {"order_id": order_id,
       "receiver_profile_photo": receiver_profile_photo,
       "title": title,
       "last_message": last_message
       }
     end

     render json: {"list": list, "page": orders.current_page, "total": total}
     return 200
   end

   #GET /chats/admin/list?page&for_admin
   def get_chat_with_admin_list
     page = params[:page].to_i
     list = []

     if page == 0
      page = 1
     elsif page < 1
      render json: {"error": "Error: page is lesser then 1."}
      return 400
     end
     
     #Faz a chamada para funções de serviço de user
     user_services = ServicesModule::V2::UserService.new

     if session_user.user_type == "user" || session_user.user_type == "professional"

       #Reescreve a váriavel for_admin recebida por parametro, caso o tipo de usuário seja user, ou professional.
       if session_user.user_type == "user"
         for_admin = 1
       else
         for_admin = 2
       end

       orders = Order.where("user_id = ? OR professional = ?", session_user.id, session_user.id)
       .order(created_at: :desc).page(page)

       total = orders.total_pages

       if ((total > 0) && (page > total) )
         render json: {"error": "Error: page is greater then total_pages."}
         return 400
       end

       #Usuario não tem pedidos validos
       if orders == nil
         render json: {"error": "Error: Current user doesn't have any valid orders."}
         return 400
       end

       for order in orders
         #Loop chegou ao fim, pois os pedidos validos acabaram
         if order == nil
           break
         end

         order_id = order.id
        
         last_chat = Chat.where(order_id: order_id)
         .where(for_admin: for_admin).last

         #Caso o usuario não tenha enviado mensagens para o admin associado a este pedido
         if last_chat == nil
          list << nil
          next
         end

         sender = User.find(last_chat.sender_id)
         receiver = User.find(last_chat.receiver_id)

         if sender.user_type != "admin"
          name = receiver.name

         else
          name = sender.name

          #Para pegar a foto do admin, caso o usuário logado seja um professional, ou um user
          receiver = sender

         end

         #Pega a foto do remetente
         receiver_profile_photo = user_services.get_profile_photo(receiver)

         if receiver_profile_photo != nil
           receiver_profile_photo = UserProfilePhotoSerializer.new(receiver_profile_photo)
         end    

         #Faz o título
         service_type = order.category.name + " - "
         title = service_type + "Suporte" + " - " + name
      
         last_message = {"message": last_chat.message, "created_at": last_chat.created_at}

         list << {"order_id": order_id,
         "receiver_profile_photo": receiver_profile_photo,
         "title": title,
         "last_message": last_message,
         }

       end

     #OBS: Aqui repito o código do for apenas para pegar o titulo de acordo. Vale notar que é impossível um determinado usuário cair nos dois for loops dessa função logado na mesma conta.
     elsif session_user.user_type == "admin"
       
       for_admin = params[:for_admin].to_i
       orders = Order.all
       .order(created_at: :desc).page(page)

       total = orders.total_pages

       if ((total > 0) && (page > total) )
         render json: {"error": "Error: page is greater then total_pages."}
         return 400
       end

       for order in orders
         #Nao tenho certeza se pode existir essa possibilidade nesse caso, mas vou manter aqui até finalizar os testes
         if order == nil
           break
         end

         order_id = order.id
      
         #Caso o user_type deste usuario seja admin, essa função espera receber como parametro 1, ou 2 para buscar respectivamente conversas com usuarios ou profissionais, com o admin
         last_chat = Chat.where(order_id: order_id)
         .where(for_admin: for_admin)
         .last

         #Caso o usuario, ou profissional associados a este pedido não tenham enviado mensagens para o admin
         if last_chat == nil
           list << nil
           next
         end
         
         sender = User.find(last_chat.sender_id)
         receiver = User.find(last_chat.receiver_id)

         if sender.user_type == "admin"
          name = receiver.name

         else

          name = sender.name

          #Para pegar a foto do remetente (professional, ou user) caso o usuário logado seja um admin
          receiver = sender
         end

         #Pega a foto do remetente
         receiver_profile_photo = user_services.get_profile_photo(receiver)

         if receiver_profile_photo != nil
           receiver_profile_photo = UserProfilePhotoSerializer.new(receiver_profile_photo)
         end

         #Faz o título
         service_type = order.category.name + " - " +  name + " - "

         if receiver.user_type  == "user" || sender.user_type == "user"
           title = service_type + "Suporte (Usuário)"
         elsif receiver.user_type == "professional" || sender.user_type == "professional"
           title = service_type + "Suporte (Profissional)"
         else
           render json: {"debug": "Error: This function logic is not prepared to deal with this type of user."}
           return 400
         end
      
         last_message = {"message": last_chat.message, "created_at": last_chat.created_at}

         list << {"order_id": order_id,
         "receiver_profile_photo": receiver_profile_photo,
         "title": title,
         "last_message": last_message
          }
       end

     #Caso usuário logado não seja admin, user, ou professional
     else
       render json: {"debug": "Error: This function logic is not prepared to deal with this type of user."}
       return 400
     end

     render json: {"list": list, "page": orders.current_page, "total": total}
     return 200
   end

  #GET /chats?id
  def show
    render json: @chat
    return 200
  end
  
  #POST /chats
  def create
    chat = Chat.new(chat_params)

    sender = User.find_by(id: chat_params[:sender_id])

    if sender == nil
      render json: {"error": "Error: Sender could not be found."}
      return 400
    end

    receiver = User.find_by(id: chat_params[:receiver_id])

    if sender == nil
      render json: {"error": "Error: Receiver could not be found."}
      return 400
    end

    order = Order.find_by(id: chat_params[:order_id])
    

    if (session_user != User.find(chat.sender_id))
      render json: {"error": "Error: Current user is not the sender."}
      return 400
    end

    if (sender == receiver)
      render json: {"error": "Error: Sender can not be the receiver."}
      return 401
    end
    
    if chat.save
      render json: chat, status: :created
    else

      #Ver como ele pode cair aqui
      render json: chat.errors, status: :unprocessable_entity
    end
    
  end
  
  private
    def set_chat
      @chat = Chat.find(params[:id])
    end

    def chat_params
      params.require(:chat).permit(:message, :is_read, :sender_id, :receiver_id, :created_at, :updated_at, :order_id, :for_admin)
    end

    def check_user_receiver
      #Não está em uso, mas escrito caso necessário.
      if (session_user != User.find(@chat.receiver_id) && session_user.user_type != "admin")
        render json: {"error": "Error: Current user is not the receiver."}
        return 400
      end

      return 200
    end

    def check_user_sender
      if (session_user != User.find(@chat.sender_id) && session_user.user_type != "admin")
        render json: {"error": "Error: Current user is not the sender."}
        return 400
      end

      return 200
    end
    
    def check_admin
      if (session_user.user_type == "admin")
        return 200
      end
      
      render json: {"error": "Error: admin privileges required."}
      return 400
    end
  
end

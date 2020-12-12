class Api::V2::ChatsController < Api::V2::ApiController
   before_action :require_login
   before_action :set_chat, only: [:show]
   before_action :set_user_services, only: [:get_chat_list, :get_chat_with_admin_list, :for_admin_get_chat_list]
   
   #GET /chats?page
   def index
     page = params[:page].to_i
     
     chats = nil
     total = nil
     
     if check_admin != 200
      render json: {"error": "Error: Admin privileges required."}
      return 400
     end

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

    order = nil
    chats = nil
    total = nil
    session_user_type = nil
    session_user_id = nil
    sender_id = nil
    receiver_id = nil
    order_status = nil
    response = nil

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
    
    total = chats.total_pages

    if total == 0
      render json: {"error": "Error: required order doesn't have any chats associated with it."}
      return 400
    elsif page > total
      render json: {"error": "Error: page is greater then total_pages."}
      return 400
    end

    session_user_type = check_user_type
    session_user_id = session_user.id

    chat_sample = chats[0]
    
    sender_id = chat_sample.sender_id
    receiver_id = chat_sample.receiver_id

    order_status = order.order_status

    if ((session_user_id != sender_id && session_user_id != receiver_id) && session_user_type != 3)
      render json: {"error": "Current user doesn't have permission to acess this."}
      return 400
    end
    
    if (session_user_type != 3 && (order_status == "finalizado" || order_status == "cancelado" || order_status == "analise" || order_status == "expirado"))
      response = {"chats": [], "current_page": 1, "total_pages": 1}
    else
      response = { chats: chats.map { |chat| ChatSerializer.new(chat) }, current_page: chats.current_page, total_pages: total }
    end

    render json: response
    return 200
   end

   #GET /chats/admin/order/?order_id&receiver_id&page
   def admin_chat_from_order
    page = params[:page].to_i

    order_id = nil
    order = nil
    receiver = nil
    session_user_type = nil
    session_user_id = nil
    receiver_id = nil
    receiver_user_type = nil
    total = nil
    response = nil

    if page == 0
      page = 1
    elsif page < 0
      render json: {"error": "Error: page is lesser then 1."}
      return 400
    end
    
    order_id = params[:order_id].to_i
    order = Order.find_by(id: order_id)
    session_user_type = check_user_type
    session_user_id = session_user.id

    if order == nil
      render json: {"error": "Error: Order does not exist."}
      return 400
    end

    receiver = User.find_by(id: params[:receiver_id].to_i)
    receiver_id = receiver.id
    receiver_user_type = receiver.user_type

    if session_user_type == 1 || session_user_type == 2
      
      if receiver_user_type != "admin"
        render json: {"error": "Error: Receiver is not an admin."}
        return 400
      end

      if session_user_type == 1
        chats = Chat.where("sender_id = ? or sender_id = ?", session_user_id, receiver_id)
        .where(order_id: order_id)
        .where("receiver_id = ? or receiver_id = ?", session_user_id, receiver_id)
        .where(for_admin: 1)
        .order(created_at: :desc).page(page)

      elsif session_user.user_type == "professional"
        chats = Chat.where("sender_id = ? or sender_id = ?", session_user_id, receiver_id)
        .where(order_id: order_id)
        .where("receiver_id = ? or receiver_id = ?", session_user_id, receiver_id)
        .where(for_admin: 2)
        .order(created_at: :desc).page(page)

      end

    elsif session_user_type == 3
      
      if receiver_user_type == "user"
        chats = Chat.where("sender_id = ? or sender_id = ?", session_user_id, receiver_id)
        .where(order_id: order_id)
        .where("receiver_id = ? or receiver_id = ?", session_user_id, receiver_id)
        .where(for_admin: 1)
        .order(created_at: :desc).page(page)
      
      elsif receiver_user_type == "professional"
        chats = Chat.where("sender_id = ? or sender_id = ?", session_user_id, receiver_id)
        .where(order_id: order_id)
        .where("receiver_id = ? or receiver_id = ?", session_user_id, receiver_id)
        .where(for_admin: 2)
        .order(created_at: :desc).page(page)

      else
        render json: {"debug": "Error: Messages between admins."}
        return 400  

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

    response = { chats: chats.map { |chat| ChatSerializer.new(chat) }, current_page: chats.current_page, total_pages: chats.total_pages }
    render json: response

    return 200
   end

   #GET /chats/list?page
   def get_chat_list
     orders = nil
     total = nil
     order = nil
     order_id = nil
     last_chat = nil
     receiver = nil
     receiver_id = nil
     receiver_profile_photo = nil
     service_type = nil
     title = nil
     last_message = nil
     another_user_id = nil

     session_user_id = session_user.id
     session_user_type = check_user_type
     page = params[:page].to_i
     list = []

     if page == 0
       page = 1
     elsif page < 1
       render json: {"error": "Error: page is lesser then 1."}
       return 400
     end

     if session_user_type == 3
      render json: {"debug": "Error: Admins should be using another function."}
      return 400
     end

     orders = Order.where("user_id = ? OR professional = ?", session_user_id, session_user_id)
     .where.not(order_status: :finalizado)
     .where.not(order_status: :cancelado)
     .where.not(order_status: :analise)
     .where.not(order_status: :expirado)
     .where.not(professional: nil)
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

       order_id = order.id
        
       last_chat = Chat.where(order_id: order_id)
       .where(for_admin: 0).last

       if session_user_type == 1
        receiver_id = order.professional_order.id
      elsif session_user_type == 2
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
       
       #Pega o id do usuário do outro lado, não importanto quem foi o último a mandar mensagem. Neste caso será sempre igual a varavel receiver_id definida acima
       another_user_id = receiver_id

       #Pega a foto do remetente
       receiver = User.find(receiver_id)
       receiver_profile_photo = @user_services.get_profile_photo(receiver)
       
       if receiver_profile_photo != nil
         receiver_profile_photo = UserProfilePhotoSerializer.new(receiver_profile_photo)
       end 

       #Faz o título
       service_type = order.category.name + " - "
       title = service_type + receiver.name
      
       last_message = {"message": last_chat.message, "created_at": last_chat.created_at}

       list << {"order_id": order_id,
       "another_user_id": another_user_id,
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
     session_user_type = check_user_type
     session_user_id = session_user.id
     
     for_admin = nil
     orders = nil
     total = nil
     order = nil
     order_id = nil
     last_chat = nil
     sender = nil
     receiver = nil
     sender_user_type = nil
     receiver_user_type = nil
     receiver_profile_photo = nil
     another_user_id = nil
     service_type = nil
     title = nil

     if page == 0
      page = 1
     elsif page < 1
      render json: {"error": "Error: page is lesser then 1."}
      return 400
     end
     
     if session_user_type == 1 || session_user_type == 2

       #Reescreve a váriavel for_admin recebida por parametro, caso o tipo de usuário seja user, ou professional.
       if session_user_type == 1
         for_admin = 1
       else
         for_admin = 2
       end

       #Pega apenas os pedidos que já tiveram troca de mensagens entre usuário e admin
       orders = Order.joins("LEFT JOIN chats on (orders.id = order_id)")
       .where("sender_id = ? OR receiver_id = ?",session_user_id, session_user_id)
       .where("chats.for_admin = ?", for_admin)
       .where.not(order_status: :analise) #Ver se precisa dos dois .where.not.
       .where.not(order_status: :expirado)
       .distinct
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

         order_id = order.id
        
         last_chat = Chat.where(order_id: order_id)
         .where(for_admin: for_admin).last

         sender = User.find(last_chat.sender_id)
         receiver = User.find(last_chat.receiver_id)

         if sender.user_type != "admin"
          name = receiver.name
         else
          name = sender.name

          #Para pegar a foto, e id do admin, caso o usuário logado seja um professional, ou um user
          receiver = sender
          another_user_id = receiver.id
         end

         #Pega a foto do remetente
         receiver_profile_photo = @user_services.get_profile_photo(receiver)

         if receiver_profile_photo != nil
           receiver_profile_photo = UserProfilePhotoSerializer.new(receiver_profile_photo)
         end    

         #Faz o título
         service_type = order.category.name + " - "
         title = service_type + "Suporte" + " - " + name
      
         last_message = {"message": last_chat.message, "created_at": last_chat.created_at}

         list << {"order_id": order_id,
         "another_user_id": another_user_id,
         "receiver_profile_photo": receiver_profile_photo,
         "title": title,
         "last_message": last_message,
         }

       end

     #OBS: Aqui repito o código do for apenas para pegar o titulo de acordo. Vale notar que é impossível um determinado usuário cair nos dois for loops dessa função logado na mesma conta.
     elsif session_user.user_type == "admin"
       
       for_admin = params[:for_admin].to_i
       orders = Order.joins("LEFT JOIN chats on (orders.id = order_id)")
       .where("chats.for_admin = ?",for_admin)
       .where.not(order_status: :analise)
       .where.not(order_status: :expirado)
       .distinct
       .order(created_at: :desc).page(page)

       total = orders.total_pages

       if ((total > 0) && (page > total) )
         render json: {"error": "Error: page is greater then total_pages."}
         return 400
       end

       for order in orders

         order_id = order.id
      
         #Caso o user_type deste usuario seja admin, essa função espera receber como parametro 1, ou 2 para buscar respectivamente conversas com usuarios ou profissionais, com o admin
         last_chat = Chat.where(order_id: order_id)
         .where(for_admin: for_admin)
         .last

         sender = User.find(last_chat.sender_id)
         receiver = User.find(last_chat.receiver_id)

         if sender.user_type == "admin"
          name = receiver.name
         else
          name = sender.name

          #Para pegar a foto, e o id do remetente (professional, ou user) caso o usuário logado seja um admin
          receiver = sender
          another_user_id = receiver.id
         end

         #Pega a foto do remetente
         receiver_profile_photo = @user_services.get_profile_photo(receiver)

         if receiver_profile_photo != nil
           receiver_profile_photo = UserProfilePhotoSerializer.new(receiver_profile_photo)
         end

         #Faz o título
         service_type = order.category.name + " - " +  name + " - "
         receiver_user_type = receiver.user_type
         sender_user_type = sender.user_type

         if receiver_user_type  == "user" || sender_user_type == "user"
           title = service_type + "Suporte (Usuário)"
         elsif receiver_user_type == "professional" || sender_user_type == "professional"
           title = service_type + "Suporte (Profissional)"
         else
           render json: {"debug": "Error: This function logic is not prepared to deal with this type of user."}
           return 400
         end
      
         last_message = {"message": last_chat.message, "created_at": last_chat.created_at}

         list << {"order_id": order_id,
         "another_user_id": another_user_id,
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

    if check_admin != 200
      render json: {"error": "Error: Admin privileges required."}
      return 400
     end

    render json: @chat
    return 200
  end
  
  #POST /chats
  def create

    chat = Chat.new(chat_params)
    sender = session_user
    receiver = User.find_by(id: chat_params[:receiver_id])

    order = nil
    sender_id = nil

    if receiver == nil
      render json: {"error": "Error: Receiver could not be found."}
      return 400
    end

    order = Order.find_by(id: chat_params[:order_id])
    
    if order == nil
      render json: {"error": "Error: Order could not be found."}
      return 400
    end
  
    if (sender == receiver)
      render json: {"error": "Error: Sender can not be the receiver."}
      return 400
    end
  
    sender_id = sender.id

    if order.user_id != sender_id && order.professional_order.id != sender_id
      render json: {"error": "Error: Permission denied. Session user is neither the sender or the receiver."}
      return 400
    end

    chat.sender_id = sender_id
    chat.for_admin = 0

    if chat.save
      render json: chat, status: :created
      return 200
    end

    #Ver como ele pode cair aqui
    render json: chat.errors, status: :unprocessable_entity

    return 400
  end
  
  #POST /chats/admin
  def create_chat_admin

    #Para mandar mensagens desassociadas de pedidos para algum admin
    chat = Chat.new(chat_params)

    sender = session_user

    sender_user_type = check_user_type

    receiver = User.find_by(id: chat_params[:receiver_id])

    receiver_user_type = receiver.user_type

    if receiver == nil
      render json: {"error": "Error: Receiver could not be found."}
      return 400
    end
  
    if (sender == receiver)
      render json: {"error": "Error: Sender can not be the receiver."}
      return 400
    end

    if sender_user_type != 3 && receiver_user_type != "admin"
      render json: {"error": "Error: Admin is neither sender or receiver."}
      return 400
    end

    #Pedido criado especialmente para se falar com o admin por fora de qualquer pedido
    chat.order_id = 170

    sender_id = sender.id
    chat.sender_id = sender_id

    if sender_user_type == 1 || receiver_user_type == "user"
      chat.for_admin = 1
    elsif sender_user_type == 2 || receiver_user_type == "professional"
      chat.for_admin = 2
    else
      render json: {"debug": "Error: This function logic is not prepared to deal with this type of user."}
      return 400
    end

    if chat.save
      render json: chat, status: :created
    else

      #Ver como ele pode cair aqui
      render json: chat.errors, status: :unprocessable_entity
    end

    return 200
  end

  #GET /chats/admin/all?page
  def for_admin_get_chat_list

    #Essa função pode ser facilmente adaptada para mostrar a lista de conversas de um usuário com os administadores caso seja necessário.
    #Basta checar se o session_user é user, ou professional, e fazer um User.where(user_type: 0).order(created_at: :desc).page(page)

    #Definicao de variaveis
    page = params[:page].to_i
    list = []
    users = nil
    total = nil
    user = nil
    user_type = nil
    chat = nil
    title = nil
    user_profile_photo = nil
    another_user_id = nil
    last_message = nil

    if check_admin != 200
      render json: {"error": "Error: admin privileges required."}
      return 400
    end
  
    if page == 0
      page = 1
    elsif page < 1
      render json: {"error": "Error: page is lesser then 1."}
      return 400
    end

    users = User.where("user_type = 1 OR user_type = 2").order(created_at: :desc).page(page)

    total = users.total_pages

    if ((total > 0) && (page > total) )
      render json: {"error": "Error: page is greater then total_pages."}
      return 400
    end

    for user in users

      if user == nil
        break
      end

      chat = Chat.where(order_id: 170).where("sender_id = ? or receiver_id = ?", user.id,user.id).last
      
      if chat == nil
        list << nil
        next
      end

      user_type = user.user_type

      if user_type == "user"
        title = "Suporte - " + user.name + " - (Usuário)"
      elsif user_type == "professional"
        title = "Suporte - " + user.name + " - (Profissional)"
      else
        render json: {"debug": "Error: This function logic is not prepared to deal with this type of user."}
        return 400
      end

      #Pega a foto do usuário
      user_profile_photo = @user_services.get_profile_photo(user)

      #Pega o id do usuário
      another_user_id = user.id

      if user_profile_photo != nil
        user_profile_photo = UserProfilePhotoSerializer.new(user_profile_photo)
      end

      last_message = {"message": chat.message, "created_at": chat.created_at}

      list << {"another_user_id": another_user_id,
        "user_profile_photo": user_profile_photo,
        "title": title,
        "last_message": last_message
        }
    end

    render json: {"list": list, "page": users.current_page, "total": total}
    return 200
  end

  #GET /chats/user/admin?receiver_id&page
  def get_chat_with_admin
    page = params[:page].to_i
    receiver_id = params[:receiver].to_i
    session_user_id = session_user.id

    if page == 0
      page = 1
    elsif page < 1
      render json: {"error": "Error: page is lesser then 1."}
      return 400
    end

    if check_admin != 200
      chats = Chat.where(order_id: 170).where("sender_id = ? OR receiver_id = ?",session_user_id, session_user_id)
      .order(created_at: :desc).page(page)
    else
      chats = Chat.where(order_id: 170).where("sender_id = ? OR receiver_id = ?",receiver_id, receiver_id)
      .order(created_at: :desc).page(page)
    end

    total = chats.total_pages

    if ((total > 0) && (page > total) )
      render json: {"error": "Error: page is greater then total_pages."}
      return 400
    end

    response = { chats: chats.map { |chat| ChatSerializer.new(chat) }, current_page: chats.current_page, total_pages: total }
    render json: response

    return 200
  end

  
  private
    def set_chat
      @chat = Chat.find_by(id: params[:id])
    end

    def chat_params
      params.require(:chat).permit(:message, :is_read, :sender_id, :receiver_id, :created_at, :updated_at, :order_id, :for_admin)
    end

    def set_user_services
      @user_services = ServicesModule::V2::UserService.new
    end
  
end

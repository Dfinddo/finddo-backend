class ServicesModule::V2::OrderService < ServicesModule::V2::BaseService

  def initialize
    @notification_service = ServicesModule::V2::NotificationService.new
    @payment_gateway_service = ServicesModule::V2::PaymentGatewayService.new
  end

  def find_order(id)
    Order.find_by(id: id)
  end

  def create_order(order_params, address_params, params)
    # quando o pedido é urgente
    if(order_params[:start_order])
      order_params[:start_order] = DateTime.parse(order_params[:start_order])
    end
    if(order_params[:end_order])
      order_params[:end_order] = DateTime.parse(order_params[:end_order])
    end

    @order = Order.new(order_params)

    orders_queue_check = nil
    transaction_check = nil
    Order.transaction do
      if(order_params[:address_id] == nil)
        @address = Address.new(address_params)
        @address.user_id = order_params[:user_id]

        @address.save
        @order.address_id = @address.id
      end

      params[:images].each do |image|
        @order.images.attach(image_io(image))
      end

      # TODO: esse if também não é mais utilizado, remover
      if !@order.start_order
        @order.start_order = (DateTime.now - 3.hours)
      end
      if !@order.end_order
        @order.end_order = @order.start_order + 7.days
      end

      if @order.save

        orders_queue_check = orders_queue_scheduler_interface(@order)
      
        if orders_queue_check[:status] == 400
          raise ActiveRecord::Rollback
          transaction_check = -1
        end

        devices = []
        
        User.where(user_type: :professional).each do |u|
          u.player_ids.each do |pl|
            devices << pl
          end
        end

        if devices.length > 0
          HTTParty.post("https://onesignal.com/api/v1/notifications", 
              body: { 
                app_id: ENV['ONE_SIGNAL_APP_ID'], 
                include_player_ids: devices,
                data: {pedido: 'novo'},
                contents: {en: "Novo pedido disponível para atendimento"} })
          
        end

        { order: @order, errors: nil }
      else

        if transaction_check == -1
          return {order: nil, errors: orders_queue_check[:error] }
        end

        return { order: nil, errors: @order.errors }

      end

    end

  end

  def associate_professional(params, order)
    user = User.find_by(id: params[:professional_id], user_type: :professional)

    if user.nil?
      raise ActiveRecord::RecordNotFound.new('Profissional não encontrado')
    end

    if order.professional_order
      raise ServicesModule::V2::ExceptionsModule::OrderWithProfessionalException.new
    end

    order.with_lock do
      order.professional_order = user

      if order.previous_budget == true
        order.order_status = :orcamento_previo
      else
        order.order_status = :agendando_visita
      end
      
      if !order.save
        raise ServicesModule::V2::ExceptionsModule::OrderException.new(order.errors)
      else
        user_devices = order.user.player_ids
        data = { pedido: 'aceito' }
        content = 'Seu pedido foi aceito por um profissional'
        @notification_service.send_notification(user_devices, data, content)
        order
      end
    end
  end

  def user_active_orders(params)
    @orders = []
    if params[:order_status]
      @orders = Order
        .includes(:address, :professional_order, 
                  :category, :user)
        .with_attached_images
        .where(user_id: params[:session_user_id], order_status: params[:order_status])
        .order(start_order: :desc).order(urgency: :asc).page(params[:page])
    else
      @orders = Order
        .includes(:address, :professional_order, 
                  :category, :user)
        .with_attached_images
        .where(user_id: params[:session_user_id])
        .order(start_order: :desc).order(urgency: :asc).page(params[:page])
    end
    
    { items: @orders.map { |order| OrderSerializer.new order }, current_page: @orders.current_page, total_pages: @orders.total_pages }
  end

  def available_orders(params)
    @orders = Order
      .includes(:address, :professional_order, 
                :category, :user)
      .with_attached_images
      .where({professional_order: nil})
      .where({order_status: :analise})
      .order(start_order: :desc).order(urgency: :asc).page(params[:page])
    
    { items: @orders.map { |order| OrderSerializer.new order }, current_page: @orders.current_page, total_pages: @orders.total_pages }
  end

  def associated_active_orders(params)
    @orders = []
    if params[:order_status]
      @orders = Order
        .includes(:address, :professional_order, 
                  :category, :user)
        .with_attached_images
        .where({professional: params[:session_user_id], order_status: params[:order_status]})
        .order(start_order: :desc).order(urgency: :asc).page(params[:page])
    else
      #Ver
      @orders = Order
        .includes(:address, :professional_order, 
                  :category, :user)
        .with_attached_images
        .where({professional: params[:session_user_id]})
        .order(start_order: :desc).order(urgency: :asc).page(params[:page])
    end

    { items: @orders.map { |order| OrderSerializer.new order }, current_page: @orders.current_page, total_pages: @orders.total_pages }
  end

  def update_order(order, order_params)
    old_status = order.order_status

    Order.transaction do
      if order.update(order_params)
  
        status_novo = ""
        if order.order_status == "agendando_visita"
          status_novo = "Agendando visita"
        elsif order.order_status == "a_caminho"
          status_novo = "Profissional à caminho"
        elsif order.order_status == "em_servico"
          status_novo = "Serviço em execução"
        elsif order.order_status == "aguardando_profissional"
          status_novo = "Aguardando profissional"
        end

        order
      else
        raise ServicesModule::V2::ExceptionsModule::OrderException(order.errors)
      end
    end
  end

  def destroy_order(order)
      order.destroy
  end

  def receive_webhook_wirecard(params)
    order_id = params[:resource][:payment][:_links][:order][:title];
    if params[:event] == "PAYMENT.IN_ANALYSIS"
      order = Order.find_by(order_wirecard_id: order_id)
      order.order_status = :processando_pagamento if order.order_status != "classificando"
      order.save
    elsif params[:event] == "PAYMENT.AUTHORIZED"
      order = Order.find_by(order_wirecard_id: order_id)
      order.paid = true
      order.order_status = :classificando

      if order.save
        devices = []
        order.professional_order.player_ids.each do |el|
          devices << el
        end
        order.user.player_ids.each do |el|
          devices << el
        end

        HTTParty.post("https://onesignal.com/api/v1/notifications", 
          body: { 
            app_id: ENV['ONE_SIGNAL_APP_ID'], 
            include_player_ids: devices,
            data: {pagamento: 'aceito'},
            
            #mudar pra recebido ou efetuado se for profissional ou usuario
            contents: {en: "Pagamento recebido\nObrigado por usar o Finddo!"} })
      end
    elsif params[:event] == "PAYMENT.CANCELLED"
      order_id = params[:resource][:payment][:_links][:order][:title];
      order = Order.find_by(order_wirecard_id: order_id)
      
      # voltar para em_servico para poder pagar de novo
      order.order_status = :em_servico

      devices = []
      order.professional_order.player_ids.each do |el|
        devices << el
      end
      order.user.player_ids.each do |el|
        devices << el
      end

      HTTParty.post("https://onesignal.com/api/v1/notifications", 
        body: { 
          app_id: ENV['ONE_SIGNAL_APP_ID'], 
          include_player_ids: devices,
          data: {pagamento: 'cancelado'},
          contents: {en: "Pagamento não efetuado\nFavor revisar informações de pagamento"} })
    end
  end

  def budget_approve(order, params)
    payload = {}
    payload[:accepted] = params[:accepted]
    payload[:order] = OrderSerializer.new order

    devices = order.professional_order.player_ids

    if params[:accepted] == nil
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        nil, 'accepted deve ser true ou false'
      )
    end

    if payload[:accepted]
      req = HTTParty.post("https://onesignal.com/api/v1/notifications", 
          body: { 
            app_id: ENV['ONE_SIGNAL_APP_ID'], 
            include_player_ids: devices,
            data: payload,
            contents: { en: "O orçamento para o pedido foi aprovado." } })
      
      order.budget.update(accepted: true)
      order.update(order_status: :agendando_visita)
      payload
    elsif order.budget.update(accepted: false)
      req = HTTParty.post("https://onesignal.com/api/v1/notifications", 
        body: { 
          app_id: ENV['ONE_SIGNAL_APP_ID'], 
          include_player_ids: devices,
          data: payload,
          contents: { en: "O orçamento para o pedido foi recusado." } })
      order
    end
  end

  def propose_budget(order, params)
    payload = {}
    order.budget.destroy if order.budget
    
    budget = Budget.new(params)
    budget.order = order
    budget.attributes = @payment_gateway_service.calculate_service_value(params[:budget])
    budget.total_value = budget.value_with_tax + budget.material_value
    budget.save

    payload[:budget] = BudgetSerializer.new budget

    devices = order.user.player_ids

    req = HTTParty.post("https://onesignal.com/api/v1/notifications", 
        body: { 
          app_id: ENV['ONE_SIGNAL_APP_ID'], 
          include_player_ids: devices,
          data: payload,
          contents: { en: "Seu pedido recebeu um orçamento." } })

    payload
  end

  def create_wirecard_order(order, price, session_user)
    Order.transaction do
      begin
        response = @payment_gateway_service.create_wirecard_order(order, price, session_user)
        parsed_response = JSON.parse(response.body)
        order.order_wirecard_own_id = parsed_response["ownId"]
        order.order_wirecard_id = parsed_response["id"]
        order.price = parsed_response["amount"]["total"]
      rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
        raise e
      end

      if order.save
        order
      else
        raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
          order.errors, 'falha ao associar pedido Wirecard com pedido na base de dados.'
        )
      end
    end
  end

  def create_payment(payment_data, order)
    begin
      response = @payment_gateway_service.create_wirecard_payment(payment_data, order)
      parsed_response = JSON.parse(response.body)
      
      order.payment_wirecard_id = parsed_response["id"]
      if order.save
        parsed_response
      else
        raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
          order.errors, 'falha ao criar pagamento na Wirecard'
        )
      end
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      raise e
    end
  end

  def cancel_order(order)
    Order.transaction do
      if order.update(order_status: :cancelado)
        devices = order.user.player_ids
        devices << order.professional_order.player_ids if order.professional_order

        @notification_service.send_notification(devices, {}, 
          content = "#{order.category.name} - Pedido cancelado")
        
        #Faz a manutenção no ciclo recursivo de final_flow_manager
        orders_queue_changer(order.id, false)

        order
      else
        raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
          order.errors, 'falha ao atualizar pedido na base de dados.'
        )
      end
    end
  end

  def disassociate_professional(order)
    Order.transaction do
      order.professional_order = nil
      order.budget.destroy if order.budget
      if order.save
        devices = []
        devices << order.professional_order.player_ids if order.professional_order

        @notification_service.send_notification(devices, {}, 
          content = "#{order.category.name} - desassociado do pedido")
        order
      else
        raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
          order.errors, 'falha ao atualizar pedido na base de dados.'
        )
      end
    end
  end

  def create_rescheduling(order, rescheduling_params)
    rescheduling_params.delete(:user_accepted)
    rescheduling_params.delete(:professional_accepted)

    order.rescheduling.destroy if order.rescheduling
    order.build_rescheduling(rescheduling_params)
    
    if order.save
      devices = []
      devices << order.professional_order.player_ids if order.professional_order
      devices << order.user.player_ids

      @notification_service.send_notification(devices, order.rescheduling, 
        content = "#{order.category.name} - reagendamento")
      order
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        order.errors, 'falha ao reagendar pedido.', 422
      )
    end
  end

  def update_rescheduling(order, user, accepted)
    order_id = order.id
    order.rescheduling.user_accepted = accepted if user == order.user
    order.rescheduling.professional_accepted = accepted if user == order.professional_order

    if order.rescheduling.save
      devices = []
      devices << order.professional_order.player_ids if order.professional_order
      devices << order.user.player_ids

      if order.rescheduling.user_accepted.nil? || order.rescheduling.professional_accepted.nil?
        @notification_service.send_notification(devices, order.rescheduling, 
          content = "#{order.category.name} - reagendamento")
        order
      elsif order.rescheduling.user_accepted == order.rescheduling.professional_accepted
        @notification_service.send_notification(devices, order.rescheduling, 
          content = "#{order.category.name} - reagendamento confirmado")
        
        #Faz a manutenção no ciclo recursivo de final_flow_manager
        orders_queue_changer(order_id, true)
        
        order
      else
        @notification_service.send_notification(devices, order.rescheduling, 
          content = "#{order.category.name} - reagendamento recusado")
        order
      end
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        order.errors, 'falha ao reagendar pedido.', 422
      )
    end
  end

  def direct_associate_professional(order, professional)
    order.update({ professional_order: professional })
  end

  # possível candidato a serviço
  def image_io(image)
    decoded_image = Base64.decode64(image[:base64])
    { io: StringIO.new(decoded_image), filename: image[:file_name] }
  end

  def expired_orders
    #Roda toda meia noite
    current_date = nil
    day = nil
    data = nil
    flag = nil
    orders = nil
    order = nil
    order_start_date = nil
    diff = nil
    diff_int = nil
    check = nil
    user = nil
    user_id = nil
    user_name = nil
    content = nil
  
    current_date = Time.now
    day = 1.day

    data = {pedido: "Expirou"}
    flag = 200
  
    orders = Order.where(order_status: :analise)
    if orders == nil || orders.length  < 1
      return 400
    end

    for order in orders
      
      order_start_date = order.start_order
      diff = (current_date - order_start_date) / day
      
      diff_int = diff.to_i
      check =  diff - diff_int

      #Independente da diferença de horas, caso o dia atual seja maior ou igual do que dia de inicio do pedido +7, esse pedido deverá ser considerado expirado.
      if diff_int == 6 && check != 0.0
        diff = diff.to_i + 1
      else
        diff = diff_int
      end
      
      user = order.user
      user_id = user.id
      user_name = user.name

      if diff >= 7
        order.order_status = :expirado
        
        if !order.save
          flag = 400

        else
          content = "Olá %s, infelizmente nenhum profissional pode atender o seu pedido. Por favor, tente novamente. Obrigado por utilizar a Finddo !"%user_name
          @notification_service.send_notification_with_user_id(user_id, data, content)

          #Faz a manutenção no ciclo recursivo de final_flow_manager
          orders_queue_changer(order.id, false)
          
        end

      end

    end

    return flag
  end

  def order_rate(order, params)

    if order.order_status != :classificando
      return {"error": "Error: Order is not on adequate status."}
    end

    user = order.user
    professional = order.professional_order

    new_user_rate = params[:user_rate].to_f
    new_professional_rate = params[:professional_rate].to_f

    if new_user_rate != nil
      order.user_rate = new_user_rate
    end

    if new_professional_rate != nil
      order.rate = new_professional_rate
    end

    if order.user_rate != nil && order.rate != nil
      order.order_status = :finalizado
    end

    if !order.save
      return {"error": "Error: order not saved."}
    end

    if new_user_rate != nil && new_user_rate > 0
      user.rate = Order.where(user: user)
      .where("user_rate > 0")
      .average(:user_rate)
      if !user.save
        return {"error": "Error: user not saved."}
      end
    end

    if new_professional_rate != nil && new_professional_rate > 0
      professional.rate = Order.where(professional_order: professional)
      .where("rate > 0")
      .average(:rate)
      if !professional.save
        return {"error": "Error: professional not saved."}
      end
    end
    
    return {"user_rate": user.rate, "professional_rate": professional.rate, "order.user_rate": order.user_rate, "order.professional_rate": order.rate}
    
  end

  def one_day_earlier_then_order_day
    current_date_start = Time.now + 1.day
    current_date_end = current_date_start + 2.day

    current_date_start = current_date_start.strftime("%Y-%m-%d")
    current_date_end = current_date_end.strftime("%Y-%m-%d")

    data = {pedido: "Falta um dia"}

    orders = Order.where("start_order >= ?", current_date_start)
    .where("start_order < ?", current_date_end)
    .where(order_status: :agendando_visita)

    for order in orders
      user = order.user
      professinal = order.professional

      user_name = user.name
      professional_name = professional.name

      user_id = user.id
      professional_id = professional.id

      address = order.address
      street = address.street
      number = address.number

      full_address = street + ' número ' + number
      district = address.district

      order_day = order.start_order
      order_day = order_day.strftime("%Y-%m-%d")

      order.order_status = :aguardando_dia_servico

      if order.save
        content = "Olá %s, gostariamos de te lembrar que você está agendado para atender um pedido no endereço: %s no bairro: %s amanhã. Atenciosamente.: Equipe Finddo." % [professional_name, full_address, district]
        try = @notification_service.send_notification_with_user_id(professional_id, data, content)

        if try == 401
          #Colocar isso num log para V3
          puts "====\n\n\nProfissional do pedido de id %s não recebeu notificação.\n\n\n ===="%order.id
        end

      else
        puts "====\n\n\nMudança de status não foi feita para o pedido de id %s.\n\n\n ===="%order.id
      end

    end

  end

  def order_day_arrived
    user = nil
    professional = nil
    user_name = nil
    professional_name = nil
    user_id = nil
    professional_id = nil
    content1 = nil
    content2 = nil
    try = nil
    failed_notifications_orders_id = []

    number_of_fails = 0
    
    data = {pedido: "Chegou o dia"}

    current_date_start = Time.now
    current_date_end = current_date_start + 1.day

    current_date_start = current_date_start.strftime("%Y-%m-%d")
    current_date_end = current_date_end.strftime("%Y-%m-%d")

    orders = Order.where("start_order >= ?", current_date_start)
    .where("start_order < ?", current_date_end)
    .where(order_status: :aguardando_dia_servico)

    for order in orders
      user = order.user
      professional = order.professional_order
      
      user_name = user.name
      professional_name = professional.name

      user_id = user.id
      professional_id = professional.id

      order.order_status = :aguardando_profissional

      if order.save
        content1 = "Olá %s. Gostariamos de te lembrar que chegou o dia de atendimento de um dos serviços que você requisitou. Atenciosamente, Equipe Finddo."%user_name
        try = @notification_service.send_notification_with_user_id(user_id, data, content1)

        content2 = "Olá %s. Gostariamos de te lembrar que chegou o dia de atendimento de um dos serviços que você aceitou. Atenciosamente, Equipe Finddo."%professional_name
        try = @notification_service.send_notification_with_user_id(professional_id, data, content2)

        if try == 401
          number_of_fails = number_of_fails + 1
          #Colocar isso num log para V3
          puts "====\n\n\n %s\n\n\n ===="%order.id
          failed_notifications_orders_id << order.id
        end

      else
        #Não salvou fazer tratamento de erro
        return {"code": 400, "number_of_fails": number_of_fails, "failed_notifications_orders_id": failed_notifications_orders_id}
      end

    end
    
    return {"code": 200, "number_of_fails": number_of_fails, "failed_notifications_orders_id": failed_notifications_orders_id}
  end

  def professional_arrived_at_service_address
    orders = Order.where(order_status: :aguardando_profissional)
    
    data = {pedido: "Chegou a hora"}

    for order in orders
      user = order.user
      professional = order.professional_order

      user_id = user.id
      professional_id = professional.id

      user_name = user.name
      professional_name = professional.name

      address = order.address
      street = address.street
      number = address.number

      full_address = street + ' número ' + number
      district = address.district

      content_cliente = "Olá %s, gostariamos de saber se o profissional %s já se encontra em sua residência. Por favor, confirme caso ele se encontre." % [professional_name, user_name]
      content_professional = "Olá %s, gostariamos de te lembrar que chegou o horário de atender o pedido no endereço: %s no bairro: %s." % [professional_name, full_address, district]

      current_date = Time.now
      current_time = current_date.strftime("%H:%M:%S")

      order_time_plus_15 = Time.parse(order.hora_inicio) + 15.minute
      order_time_plus_15 = order_time_plus_15.strftime("%H:%M:%S")

      if current_time >= order_time_plus_15
        order.order_status = :a_caminho

        if order.save
          @notification_service.send_notification_with_user_id(user_id, data, content_cliente)
          @notification_service.send_notification_with_user_id(professional_id, data, content_professional)
        end
        
      end
      
    end
  end

  def change_to_em_servico(order)
    order_id = order.id
    
    if order.order_status == "a_caminho"
      order.order_status = :em_servico

      if order.save
        #Para interromper o ciclo recursivo de final_flow_manager
        orders_queue_recursion_manager(order_id)

        return order
      end

      return 401
      
    else
      return 400
    end

  end

  def orders_queue_scheduler_interface(order)
    orders_queue_params = {order_id: order.id}
    orders_queue_entry = OrdersQueue.new(orders_queue_params)

    if !orders_queue_entry.save
      return {"error": "Fatal error: orders_queue_entry couldn't be created.", "status": 400}
    end

    start_order = order.start_order.strftime("%Y-%m-%d %H:%M:%S")

    print "\n\n\n==== %s ====\n\n\n"%start_order
    
    EnqueueOrdersJob.new.perform({"order_id": order.id, "start_order": start_order})

    return {"error": nil, "status": 200}
  end

  def final_flow_manager(order_id, notification_type)
    data = {pedido: "Chegou a hora"}

    transaction_check = nil
    Order.transaction do

      order = Order.find_by(id: order_id)
      order_status = order.order_status
      start_order = order.start_order
      
      if order_status != :agendando_visita
        transaction_check = -1
        puts "\n\n\n==== Error: Incorrect order_status. ====\n==== status: %s ====\n\n\n"""%order_status
        raise ActiveRecord::Rollback
      end

      #Ver se precisa converter ambos para string antes de comparar
      start_order = start_order.strftime("%Y-%m-%d %H:%M:%S")
      
      current_date = Time.now

      #Ajustar essa variavel de acordo com as regras de negócio
      current_date_one_more_day = current_date + 1.day
      current_date = current_date.strftime("%Y-%m-%d %H:%M:%S")

      orders_queue_counterpart = OrdersQueue.find_by(order_id: order_id)

      if orders_queue_counterpart == nil
        transaction_check = -2
        raise ActiveRecord::Rollback
        puts "\n\n\n==== Error: Order not found in OrdersQueues. ====\n\n\n"""
      end

      # Para notificação
      user = order.user
      professional = order.professional_order
      user_id = user.id
      professional_id = professional.id
      user_name = user.name
      professional_name = professional.name
      address = order.address
      street = address.street
      number = address.number
      full_address = street + ' número ' + number
      district = address.district

      if start_order >= current_date && start_order <= current_date_one_more_day
        
        #Manda notificação caso essa seja a primeira chamada dessa função em seu ciclo recursivo
        if notification_type == "first call"
          
          #Aqui poderia fazer uma lógica para colocar :aguardando_profissional, e apenas mudar para :a_caminho quando o profissional confirmar que está realmente a caminho.
          order.status = :a_caminho

          if order.save
            content_cliente = "Olá %s, gostariamos de saber se o profissional %s já se encontra em sua residência. Por favor, confirme fazendo x coisa caso ele se encontre. Atenciosamente: Equipe Finddo." % [professional_name, user_name]
            content_professional = "Olá %s, gostariamos de te lembrar que chegou o horário de atender o pedido no endereço: %s no bairro: %s. Atenciosamente: Equipe Finddo." % [professional_name, full_address, district]
            
            @notification_service.send_notification_with_user_id(user_id, data, content_cliente)
            @notification_service.send_notification_with_user_id(professional_id, data, content_professional)
            
          else
            transaction_check = -3
            puts "\n\n\n==== Error: Order coudn't be saved. ====\n\n\n"""
            raise ActiveRecord::Rollback
          end

        #Manda notificação apenas para o profissional caso essa função já tenha entrado em recursão
        elsif notification_type == "next calls"
          content_professional = "Olá %s, essa notificação será reenviada a cada 15 minutos até que seu cliente confirme a sua chegada no endereço: %s no bairro: %s. Atenciosamente: Equipe Finddo." % [professional_name, full_address, district]

          @notification_service.send_notification_with_user_id(professional_id, data, content_professional)
        end
          
      else
        transaction_check = -4
        puts "\n\n\n==== Error: Dates mismatch. ====\n\n\n"""
        raise ActiveRecord::Rollback
      end

    end

    #Retornando valores para o job FinalFlowManagerSchedulerJob para caso um dia queira-se implementar alguma funcionalidade em cima disso.
    if transaction_check == -1
      return -1
    elsif transaction_check == -2
      return -2
    elsif transaction_check == -3
      return -3
    elsif transaction_check == -4
      return -4
    end
    
    order = Order.find_by(id: order_id)

    #São feitas checagens imediatamente antes da chamada, e durante ela, para evitar conflitos de status ou chamadas de funcoes desnecessárias.
    order_status = order.order_status

    if order_status == :a_caminho || order_status == :em_servico
      puts "\n\n\n==== orders_queue_recursion_manager called. ====\n\n\n"""

      #Chamada de orders_queue_recursion_manager passando como argumento o id do pedido
      orders_queue_recursion_manager(order_id)
      return 1

    else

      #Caso aconteça uma mudança de status no meio da execução desta função
      puts "\n\n\n==== Recursion finished. ====\n\n\n"""
      
      return 0
    end

  end

  def orders_queue_recursion_manager(order_id)
    order = Order.find_by(id: order_id)
    order_status = order.order_status

    #Retira as chamadas recursivas para final_flow_manager dele, e celeta o pedido correspondente em Orders_queue.
    if order_status == :em_servico

      order_id = order.id.to_s
      job_name = 'final_flow_manager in 15 minutes for order with id: ' + order_id

      Sidekiq.set_schedule(job_name, {'enabled' => false })
      
      OrdersQueue.find_by(id: order_id.to_i).destroy

      puts "\n\n\n==== Recursion finished. ====\n\n\n"""
      return 0

    else
      puts "\n\n\n==== Function scheduled. ====\n\n\n"""
      CallFinalFlowManagerIn15MinutesJob.new.perform(order_id)
      return 1
    end

  end

  #Deve ser chamada caso ocorra alguma mudança significativa de status com algum pedido.
  def orders_queue_changer(order_id, reschedule)
    transaction_check = nil
    OrdersQueue.transaction do

      order = Order.find_by(id: order_id)

      if order == nil
        transaction_check = -1

        if reschedule == false
          call_method = 'Regular'
        else
          call_method = 'Rescheduling'
        end
        
        puts "\n\n\n==== Error: Order not found (Called by %s method). ====\n\n\n"%call_method
        raise ActiveRecord::Rollback
      end

      order_status = order.order_status

      orders_queue_counterpart = OrdersQueue.find_by(order_id: order_id)

      if orders_queue_counterpart == nil
        transaction_check = -2
        puts "\n\n\n==== Error: Order not found in OrdersQueues. ====\n\n\n"""
        raise ActiveRecord::Rollback
      end

      start_order = order.start_order.strftime("%Y-%m-%d %H:%M:%S")

      job_name_at_date = 'final_flow_manager at: ' + start_order + ' for order with id: ' + order_id.to_s
      job_name_in_15 = 'final_flow_manager in 15 minutes for order with id: ' + order_id

      #Desativa todos os possiveis jobs agendados para este serviço
      Sidekiq.set_schedule(job_name_at_date, {'enabled' => false })
      Sidekiq.set_schedule(job_name_in_15, {'enabled' => false })

      if order_status == "cancelado" || order_status == "expirado"
        OrdersQueue.find_by(id: order_id.to_i).destroy
      end

      #Caso o pedido esteja sendo re-agendado
      if reschedule == true

        new_start_order = order.rescheduling.date_order

        if new_start_order == nil
          transaction_check = -3
          puts "\n\n\n==== Error: New order schedule couldn't be found at order.rescheduling. ====\n\n\n"""
          raise ActiveRecord::Rollback
        end
        
        #Re-agenda final_flow_manager para rodar na nova data reiniciando o ciclo
        EnqueueOrdersJob.new.perform({"order_id": order_id, "start_order": new_start_order})
        puts "\n\n\n==== final_flow_manager rescheduled. ====\n\n\n"
        transaction_check = 1
      end


    end

    if transaction_check == -1
      return -1
    elsif transaction_check == -2
      return -2
    elsif transaction_check == -3
      return -3
    elsif transaction_check == 1
      return 1
    end

    return 0
    
  end

  def request_cancelation(order)
    order.order_status = :checando_cancelado
    if !order.save
      return {"error": "Error. Coudn't change order status", "status": 400}
    else
      return {"error": nil, "status": 200}
    end
  end

end
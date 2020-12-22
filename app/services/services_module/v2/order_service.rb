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
        { order: nil, errors: @order.errors }
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

        if status_novo != "" && order.order_status != old_status
          devices = order.player_ids
          data = { pedido: 'status' }
          content = "#{order.category.name}\n#{status_novo}"
          @notification_service.send_notification(devices, data, content)
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
      order.order_status = :processando_pagamento if order.order_status != "finalizado"
      order.save
    elsif params[:event] == "PAYMENT.AUTHORIZED"
      order = Order.find_by(order_wirecard_id: order_id)
      order.paid = true
      order.order_status = :finalizado

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
        end

      end

    end

    return flag
  end

  def order_rate(order, params)
    user = order.user
    professional = order.professional_order

    new_user_rate = params[:user_rate].to_f
    new_professional_rate = params[:professional_rate].to_f

    if new_user_rate == nil
      new_user_rate = 0
    end

    if new_professional_rate == nil
      new_professional_rate = 0
    end

    order.user_rate = new_user_rate
    order.rate = new_professional_rate

    order.order_status = :finalizado
    if !order.save
      return {"error:": "Error: order not saved."}
    end

    if new_user_rate > 0
      user.rate = Order.where(user: user)
      .where("user_rate > 0")
      .average(:user_rate)
      if !user.save
        return {"error:": "Error: user not saved."}
      end
    end

    if new_professional_rate > 0
      professional.rate = Order.where(professional_order: professional)
      .where("rate > 0")
      .average(:rate)
      if !professional.save
        return {"error:": "Error: professional not saved."}
      end
    end
    
    return {"user_rate": user.rate, "professional_rate": professional.rate, "order.user_rate": order.user_rate, "order.professional_rate": order.rate}
    
  end
  
end
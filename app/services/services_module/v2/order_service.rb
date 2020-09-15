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
      order.order_status = :orcamento_previo
      
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
        .where(user_id: params[:user_id], order_status: params[:order_status])
        .order(start_order: :desc).page(params[:page])
    else
      @orders = Order
        .includes(:address, :professional_order, 
                  :category, :user)
        .with_attached_images
        .where(user_id: params[:user_id])
        .order(start_order: :desc).page(params[:page])
    end
    
    { items: @orders.map { |order| OrderSerializer.new order }, current_page: @orders.current_page, total_pages: @orders.total_pages }
  end

  def available_orders(params)
    @orders = Order
      .includes(:address, :professional_order, 
                :category, :user)
      .with_attached_images
      .where({professional_order: nil})
      .where.not(order_status: :finalizado)
      .where.not(order_status: :cancelado)
      .where.not(order_status: :processando_pagamento)
      .where.not(order_status: :recusado)
      .order(urgency: :asc).order(start_order: :asc).page(params[:page])
    
    { items: @orders.map { |order| OrderSerializer.new order }, current_page: @orders.current_page, total_pages: @orders.total_pages }
  end

  def associated_active_orders(params)
    @orders = []
    if params[:order_status]
      @orders = Order
        .includes(:address, :professional_order, 
                  :category, :user)
        .with_attached_images
        .where({professional: params[:user_id], order_status: params[:order_status]})
        .order(urgency: :asc).order(start_order: :desc).page(params[:page])
    else
      @orders = Order
        .includes(:address, :professional_order, 
                  :category, :user)
        .with_attached_images
        .where({professional: params[:user_id]})
        .order(urgency: :asc).order(start_order: :desc).page(params[:page])
    end

    { items: @orders.map { |order| OrderSerializer.new order }, current_page: @orders.current_page, total_pages: @orders.total_pages }
  end

  def update_order(order, order_params)
    old_status = order.order_status

    Order.transaction do
      if order.update(order_params)
        #devices = []
        #order.user.player_ids.each do |el|
        #  devices << el
        #end

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

        if order.user_rate > 0
          order_user = order.user
          order_user.rate = Order.where(user: order.user).average(:user_rate)
          order_user.save!
        end

        if order.rate > 0
          professional_user = order.professional_order
          professional_user.rate = Order.where(professional_order: professional_user).average(:rate)
          professional_user.save!
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

    if devices.empty?
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        nil, 'O profissional não está logado.', 422
      )
    elsif payload[:accepted]
      req = HTTParty.post("https://onesignal.com/api/v1/notifications", 
          body: { 
            app_id: ENV['ONE_SIGNAL_APP_ID'], 
            include_player_ids: devices,
            data: payload,
            contents: { en: "O orçamento para o pedido foi aprovado." } })
      
      if req.code == 200
        order.budget.update(accepted: true)
        payload
      else
        raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
          nil, 'Falha ao enviar a notificação.'
        )
      end
    else
      if order.update({ order_status: :cancelado })
        req = HTTParty.post("https://onesignal.com/api/v1/notifications", 
          body: { 
            app_id: ENV['ONE_SIGNAL_APP_ID'], 
            include_player_ids: devices,
            data: payload,
            contents: { en: "O orçamento para o pedido foi recusado." } })
  
        if req.code == 200
          order.budget.update(accepted: false)
        else
          raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
            nil, 'Falha ao enviar a notificação.'
          )
        end
      end
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

  # possível candidato a serviço
  def image_io(image)
    decoded_image = Base64.decode64(image[:base64])
    { io: StringIO.new(decoded_image), filename: image[:file_name] }
  end
end
class ServicesModule::V2::OrdersService < ServicesModule::V2::BaseService

  def initialize
    @notification_service = ServicesModule::V2::NotificationService.new
  end

  def find_order(id)
    Order.find_by(id: id)
  end

  def create_order(order, address, images, professional_id)
    # quando o pedido é urgente
    order.start_order = DateTime.parse(order.start_order) if order.start_order
    order.end_order = DateTime.parse(order.end_order) if order.end_order

    new_order = Order.new(order)

    if(order.address_id.nil?)
      order_address = Address.new(address)
      order_address.user_id = order[:professional_id]

      order_address.save
      new_order.address_id = order_address.id
    end

    images.each do |image|
      new_order.images.attach(image_io(image))
    end

    if new_order.save
      devices = []

      # mover para método em user_service também
      User.where(user_type: :professional).each do |u|
        u.player_ids.each do |pl|
          devices << pl
        end
      end

      if devices.length > 0
        @notification_service
          .send_notification(devices, { pedido: 'novo' }, 
            contents = { 'en': "Novo pedido disponível para atendimento" })
      end

      new_order
    else
      new_order.errors
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
      order.order_status = :a_caminho
      
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
    @orders = Order
      .includes(:address, :professional_order, 
                :category, :user)
      .with_attached_images
      .where(user_id: params[:user_id])
      .order(order_status: :asc).order(start_order: :asc).page(params[:page])
    
    { items: @orders, current_page: @orders.current_page, total_pages: @orders.total_pages }
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
    
    { items: @orders, current_page: @orders.current_page, total_pages: @orders.total_pages }
  end

  def associated_active_orders(params)
    @orders = Order
      .includes(:address, :professional_order, 
                :category, :user)
      .with_attached_images
      .where({professional: params[:user_id]}).page(params[:page])

    { items: @orders, current_page: @orders.current_page, total_pages: @orders.total_pages }
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

  # possível candidato a serviço
  def image_io(image)
    decoded_image = Base64.decode64(image[:base64])
    { io: StringIO.new(decoded_image), filename: image[:file_name] }
  end
end
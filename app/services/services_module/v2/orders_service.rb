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

  # possível candidato a serviço
  def image_io(image)
    decoded_image = Base64.decode64(image[:base64])
    { io: StringIO.new(decoded_image), filename: image[:file_name] }
  end
end
class OrdersController < ApplicationController
  before_action :authenticate_user!, except: [:payment_webhook]
  before_action :set_order, only: [:show, :update, :destroy, :associate_professional]

  # GET /orders
  def index
    @orders = Order.all

    render json: @orders
  end

  # GET /orders/1
  def show
    render json: @order
  end

  # PUT /orders/associate/1/2
  def associate_professional
    @user = User.find(params[:professional_id])

    if !@user
      render json: {error: 'profissional não encontrado'}, status: :not_found
      return
    end

    if @order.professional_order
      render json: {error: 'pedido já possui profissional'}, status: :not_found
      return
    end

    @order.with_lock do
      @order.professional_order = @user
      @order.assign_attributes(order_params)
      @order.order_status = :a_caminho
      if @order.save
        render json: @order
      else
        render json: @order.errors, status: :unprocessable_entity
      end
    end

    devices = []
    client = User.find(@order.user_id)
    client.player_ids.each { |player| devices << player }
    return if devices.empty?

    HTTParty.post('https://onesignal.com/api/v1/notifications', body: {
      app_id: ENV['ONE_SIGNAL_APP_ID'],
      include_player_ids: devices,
      data: { pedido: 'aceito' },
      contents: { en: 'Seu pedido foi aceito por um profissional' }
    })
  end

  # GET /orders/user/:user_id/active
  def user_active_orders
    @orders = Order.where user_id: params[:user_id]

    render json: @orders
  end

  # GET /orders/available
  def available_orders
    @orders = Order.where({professional_order: nil}).order(urgency: :asc).order(start_order: :asc)

    render json: @orders
  end

  # GET /orders/active_orders_professional/:user_id
  def associated_active_orders
    @orders = Order.where({professional: params[:user_id]})

    render json: @orders
  end

  # POST /orders
  def create
    # quando o pedido é urgente
    if(order_params[:start_order])
      order_params[:start_order] = DateTime.parse(order_params[:start_order])
    end
    if(order_params[:end_order])
      order_params[:end_order] = DateTime.parse(order_params[:end_order])
    end

    @order = Order.new(order_params)

    if(order_params[:address_id] == nil)
      @address = Address.new(address_params)
      @address.user_id = order_params[:user_id]

      @address.save
      @order.address_id = @address.id
    end

    params[:images].each do |image|
      @order.images.attach(image_io(image))
    end

    # quando o pedido não é urgente
    if !@order.start_order
      @order.start_order = (DateTime.now - 3.hours)
    end
    if !@order.end_order
      @order.end_order = @order.start_order + 7.days - 3.hours
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

      render json: @order, status: :created
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /orders/1
  def update
    old_status = @order.order_status
    if @order.update(order_params)
      devices = []
      @order.user.player_ids.each do |el|
        devices << el
      end

      status_novo = ""
      if @order.order_status == "agendando_visita"
        status_novo = "Agendando visita"
      elsif @order.order_status == "a_caminho"
        status_novo = "Profissional à caminho"
      elsif @order.order_status == "em_servico"
        status_novo = "Serviço em execução"
      end

      if status_novo != "" && status_novo != old_status
        HTTParty.post("https://onesignal.com/api/v1/notifications", 
        body: { 
          app_id: ENV['ONE_SIGNAL_APP_ID'], 
          include_player_ids: devices,
          data: {pedido: 'status'},
          contents: {en: "#{@order.category.name}\n#{status_novo}"} })
      end

      render json: @order
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end

  # DELETE /orders/1
  def destroy
    @order.destroy
  end

  def payment_webhook
    order_id = params[:resource][:payment][:_links][:order][:title];
    if params[:event] == "PAYMENT.IN_ANALYSIS"
      @order = Order.find_by(order_wirecard_id: order_id)
      @order.order_status = :processando_pagamento if @order.order_status != "finalizado"
      @order.save
    elsif params[:event] == "PAYMENT.AUTHORIZED"
      @order = Order.find_by(order_wirecard_id: order_id)
      @order.paid = true
      @order.order_status = :finalizado

      if @order.save
        devices = []
        @order.professional_order.player_ids.each do |el|
          devices << el
        end
        @order.user.player_ids.each do |el|
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
      @order = Order.find_by(order_wirecard_id: order_id)
      
      # voltar para em_servico para poder pagar de novo
      @order.order_status = :em_servico

      devices = []
      @order.professional_order.player_ids.each do |el|
        devices << el
      end
      @order.user.player_ids.each do |el|
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def order_params
      params.require(:order)
        .permit(
          :category_id, :description, 
          :user_id, :urgency,
          :start_order, :end_order,
          :order_status, :price, 
          :paid, :address_id,
          :rate, :order_wirecard_own_id,
          :order_wirecard_id, :payment_wirecard_id,
          :hora_inicio, :hora_fim,
          :user_rate)
    end

    def address_params
      params.require(:address)
        .permit(
          :cep, :complement, :district, :name,
          :number, :selected, :street
        )
    end

    def image_io(image)
      decoded_image = Base64.decode64(image[:base64])
      { io: StringIO.new(decoded_image), filename: image[:file_name] }
    end
end

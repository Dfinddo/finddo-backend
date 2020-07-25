class Api::V2::OrdersController < Api::V2::ApiController
  before_action :set_services
  before_action :require_login, except: [:payment_webhook]
  before_action :set_order, only: [:show, :update, :destroy, :associate_professional, :propose_budget, :budget_approve]

  # GET api/v2/orders/:id
  def show
    render json: @order
  end

  # PUT /orders/associate/1/2 - /orders/associate/:id/:professional_id
  def associate_professional
    begin
      @order_service.associate_professional(params, @order)
    rescue ServicesModule::V2::ExceptionsModule::OrderWithProfessionalException => e
      render json: { error: e }
    rescue ActiveRecord::RecordNotFound => not_found_e
      render json: { error: not_found_e }
    rescue ServicesModule::V2::ExceptionsModule::OrderException => oe
      render json: oe.order_errors
    end
  end

  # GET /orders/user/:user_id/active
  def user_active_orders
    render json: @order_service.user_active_orders(params)
  end

  # GET /orders/available
  def available_orders
    render json: @order_service.available_orders(params)
  end

  # GET /orders/active_orders_professional/:user_id
  def associated_active_orders
    render json: @order_service.associated_active_orders(params)
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

      render json: @order, status: :created
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /orders/1
  def update
    @order_service.update_order(@order, order_params)
  end

  # DELETE /orders/1
  def destroy
    @order.destroy
  end

  # POST /orders/payment_webhook
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

  def budget_approve
    payload = {}
    payload[:accepted] = params[:accepted]
    payload[:order] = OrderSerializer.new @order

    devices = @order.professional_order.player_ids

    if params[:accepted] == nil
      render json: { erro: 'accepted deve ser true ou false' }, status: :internal_server_error
      return
    end

    if devices.empty?
      render json: { erro: 'O profissional não está logado.' }, status: :unprocessable_entity
    elsif payload[:accepted]
      req = HTTParty.post("https://onesignal.com/api/v1/notifications", 
          body: { 
            app_id: ENV['ONE_SIGNAL_APP_ID'], 
            include_player_ids: devices,
            data: payload,
            contents: { en: "O orçamento para o pedido foi aprovado." } })
      
      if req.code == 200
        @order.budget.update(accepted: true)
        render json: payload, status: :ok
      else
        render json: { erro: 'Falha ao enviar a notificação.' }, status: :internal_server_error
      end
    else
      if @order.update({ order_status: :cancelado })
        req = HTTParty.post("https://onesignal.com/api/v1/notifications", 
          body: { 
            app_id: ENV['ONE_SIGNAL_APP_ID'], 
            include_player_ids: devices,
            data: payload,
            contents: { en: "O orçamento para o pedido foi recusado." } })
  
        if req.code == 200
          @order.budget.update(accepted: false)
          render json: payload, status: :ok
        else
          render json: { erro: 'Falha ao enviar a notificação.' }, status: :internal_server_error
        end
      end
    end
  end

  def propose_budget
    payload = {}
    @order.budget.destroy if @order.budget
    budget = Budget.create(order: @order, budget: params[:budget])
    payload[:budget] = budget
    @order.reload
    payload[:order] = OrderSerializer.new @order

    devices = @order.user.player_ids

    if devices.empty?
      budget.destroy
      render json: { erro: 'O usuário não está logado.' }, status: :unprocessable_entity
    else
      req = HTTParty.post("https://onesignal.com/api/v1/notifications", 
          body: { 
            app_id: ENV['ONE_SIGNAL_APP_ID'], 
            include_player_ids: devices,
            data: payload,
            contents: { en: "Seu pedido recebeu um orçamento." } },
            :debug_output => $stdout)
      
      print "===================================="
      print req
      if req.code == 200
        render json: payload, status: :ok
      else
        render json: { erro: 'Falha ao enviar a notificação.' }, status: :internal_server_error
      end
    end
  end

  private

    def set_services
      @order_service = ServicesModule::V2::OrderService.new
    end

    def set_order
      @order = @order_service.find_order(params[:id])

      if @order.nil?
        render json: { error: 'Pedido não encontrado' }, status: :not_found
        return
      end
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

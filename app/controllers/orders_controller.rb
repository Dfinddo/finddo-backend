class OrdersController < ApplicationController
  before_action :authenticate_user!, except: [:payment_webhook]
  before_action :set_order, only: [:show, :update, :destroy, :associate_professional, :propose_budget, :budget_approve]

  # GET /orders/1
  def show
    render json: @order
  end

  # PUT /orders/associate/1/2 - /orders/associate/:id/:professional_id
  def associate_professional
    @user = User.find_by(id: params[:professional_id], user_type: :professional)

    if !@user
      render json: {error: 'profissional não encontrado'}, status: :forbidden
      return
    end

    if @order.professional_order
      render json: {error: 'pedido já possui profissional'}, status: :forbidden
      return
    end

    @order.with_lock do
      @order.professional_order = @user
      # TODO: essa linha não tem sentido, o objetivo desse endpoint é apenas
      # modificar o estado do status pedido para a_caminho
      @order.assign_attributes(order_params)
      @order.order_status = :a_caminho
      if @order.save
        render json: @order
      else
        render json: @order.errors, status: :unprocessable_entity
        return
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
    @orders = Order
      .includes(:address, :professional_order, 
                :category, :user)
      .with_attached_images
      .where(user_id: params[:user_id])
      .order(order_status: :asc).order(start_order: :asc)

    render json: @orders
  end

  # GET /orders/available
  def available_orders
    @orders = Order
      .includes(:address, :professional_order, 
                :category, :user)
      .with_attached_images
      .where({professional_order: nil})
      .where.not(order_status: :finalizado)
      .where.not(order_status: :cancelado)
      .where.not(order_status: :processando_pagamento)
      .where.not(order_status: :recusado)
      .order(urgency: :asc).order(start_order: :asc)

    render json: @orders
  end

  # GET /orders/active_orders_professional/:user_id
  def associated_active_orders
    @orders = Order
      .includes(:address, :professional_order, 
                :category, :user)
      .with_attached_images
      .where({professional: params[:user_id]})

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

      if status_novo != "" && @order.order_status != old_status
        HTTParty.post("https://onesignal.com/api/v1/notifications", 
        body: { 
          app_id: ENV['ONE_SIGNAL_APP_ID'], 
          include_player_ids: devices,
          data: {pedido: 'status'},
          contents: {en: "#{@order.category.name}\n#{status_novo}"} })
      end

      if @order.user_rate > 0
        order_user = @order.user
        order_user.rate = Order.where(user: @order.user).average(:user_rate)
        order_user.save
      end

      if @order.rate > 0
        professional_user = @order.professional_order
        professional_user.rate = Order.where(professional_order: professional_user).average(:rate)
        professional_user.save
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
    payload[:approved] = params[:approved]
    payload[:order] = OrderSerializer.new @order

    devices = @order.professional_order.player_ids

    if devices.empty?
      render json: { erro: 'O profissional não está logado.' }, status: :unprocessable_entity
    elsif payload[:approved]
      req = HTTParty.post("https://onesignal.com/api/v1/notifications", 
          body: { 
            app_id: ENV['ONE_SIGNAL_APP_ID'], 
            include_player_ids: devices,
            data: payload,
            contents: { en: "O orçamento para o pedido foi aprovado." } })
      
      if req.code == 200
        @order.budget.destroy
        @order.reload
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
          @order.budget.destroy
          @order.reload
          render json: payload, status: :ok
        else
          render json: { erro: 'Falha ao enviar a notificação.' }, status: :internal_server_error
        end
      end
    end
  end

  def propose_budget
    payload = {}
    budget = Budget.create(order: @order, budget: params[:budget])
    payload[:budget] = budget
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

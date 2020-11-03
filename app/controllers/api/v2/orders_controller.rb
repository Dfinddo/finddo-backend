class Api::V2::OrdersController < Api::V2::ApiController
  before_action :set_services
  before_action :require_login, except: [:payment_webhook]
  before_action :set_order, only: [:show, :update, :destroy, 
    :associate_professional, :propose_budget, :budget_approve, :create_order_wirecard,
    :create_payment, :cancel_order, :disassociate_professional, :create_rescheduling,
    :update_rescheduling, :direct_associate_professional]

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
    create_state = nil
    
    if !params.has_key?(:address)
      create_state = @order_service.create_order(order_params, nil, params)
    else
      create_state = @order_service.create_order(order_params, address_params, params)
    end

    if create_state[:order]
      render json: create_state[:order], status: :created
    else
      render json: create_state[:errors], status: :bad_request
    end
  end

  # PATCH/PUT /orders/1
  def update
    @order_service.update_order(@order, order_params)
  end

  # DELETE /orders/1
  def destroy
    @order_service.destroy_order(@order)
  end

  # POST /orders/payment_webhook
  def payment_webhook
    @order_service.receive_webhook_wirecard(params)
  end

  def budget_approve
    begin
      payload = @order_service.budget_approve(@order, params)
      render json: payload, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def propose_budget
    begin
      payload = @order_service.propose_budget(@order, budget_params)
      render json: payload, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def create_order_wirecard
    begin
      payload = @order_service.create_wirecard_order(@order, params[:price], session_user)
      render json: payload, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def create_payment
    begin
      payment_data = @order_service.create_payment(params[:payment_data], @order)
      render json: payment_data, status: :created
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def cancel_order
    begin
      @order = @order_service.cancel_order(@order)
      render json: @order, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def disassociate_professional
    begin
      @order = @order_service.disassociate_professional(@order)
      render json: @order, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def create_rescheduling
    begin
      @order = @order_service.create_rescheduling(@order, rescheduling_params)
      render json: @order, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def update_rescheduling
    begin
      @order = @order_service
        .update_rescheduling(@order, session_user, 
        ActiveModel::Type::Boolean.new.cast(params[:accepted]))
      render json: @order, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def direct_associate_professional
    user = User.find_by(id: params[:professional_id])
    @order_service.direct_associate_professional(@order, user)
    @order.reload

    render json: @order
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
          :user_rate, :previous_budget,
          :previous_budget_value,
          :professional_order,
          :selected_professional,
          :order_chat)
    end

    def address_params
      params.require(:address)
        .permit(
          :cep, :complement, :district, :name,
          :number, :selected, :street
        )
    end

    def rescheduling_params
      params.require(:rescheduling)
        .permit(
          :date_order, :hora_inicio, :hora_fim,
          :user_accepted, :professional_accepted
        )
    end

    def budget_params
      params.permit(:budget, :is_previous, :material_value)
    end

    def image_io(image)
      decoded_image = Base64.decode64(image[:base64])
      { io: StringIO.new(decoded_image), filename: image[:file_name] }
    end
end

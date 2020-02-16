class OrdersController < ApplicationController
  before_action :authenticate_user!
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
  end

  # GET /orders/user/:user_id/active
  def user_active_orders
    @orders = Order.where user_id: params[:user_id]

    render json: @orders
  end

  # GET /orders/available
  def available_orders
    @orders = Order.where({professional_order: nil}).where(["start_order > :start",{start: (Time.now - 3.days - 3.hours)}])

    render json: @orders
  end

  # GET /orders/active_orders_professional/:user_id
  def associated_active_orders
    @orders = Order.where({professional: params[:user_id]})

    render json: @orders
  end

  # POST /orders
  def create
    if(order_params[:start_order])
      order_params[:start_order] = DateTime.parse(order_params[:start_order])
    end
    @order = Order.new(order_params)

    @order.images.attach(io: image_io, filename: image_name)

    @order.address_id = @order.user.addresses[0].id

    if !@order.start_order
      @order.start_order = (DateTime.now - 3.hours)
    elsif !@order.end_order
      @order.end_order = @order.start_order + 7.days - 3.hours
    end

    if @order.save
      render json: @order, status: :created
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /orders/1
  def update
    if @order.update(order_params)
      render json: @order
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end

  # DELETE /orders/1
  def destroy
    @order.destroy
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
          :user_id,
          :start_order, :end_order,
          :order_status, :price, :paid)
    end

    def image_io
      decoded_image = Base64.decode64(params[:images][:base64])
      StringIO.new(decoded_image)
    end
    
    def image_name
      params[:images][:file_name]
    end
end

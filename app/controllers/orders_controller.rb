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

  # PUT /orders/associate/1
  def associate_professional
    @order.with_lock do
      if @order.update(order_params)
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
    @orders = Order.where({professional_order: nil}).where(["start_order > :start",{start: DateTime.now}])

    render json: @orders
  end

  # POST /orders
  def create
    if(order_params[:start_order])
      order_params[:start_order] = DateTime.parse(order_params[:start_order])
    end
    @order = Order.new(order_params)

    @order.address_id = @order.user.addresses[0].id

    if !@order.start_order
      @order.start_order = DateTime.now
    elsif !@order.end_order
      @order.end_order = @order.start_order + 7.days
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
          :user_id, :professional,
          :start_order, :end_order,
          :order_status, :price, :paid)
    end
end

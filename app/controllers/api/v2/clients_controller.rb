class Api::V2::ClientsController < ApplicationController
  before_action :set_client, only: [:show]

  def create
    @client = Client.new(client_params)
    @client.rate += 1

    if @client.save
      render json: @client, status: :created
    else
      render json: @client.errors, status: :unprocessable_entity
    end
  end

  def show
    render json: @client
  end

  private

    def set_client
      @client = Client.find(params[:id])
    end

    def client_params
      params.require(:client).permit(:name, :rate)
    end
end

class DrumsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_drum, only: [:show, :update, :destroy]

  # GET /drums
  def index
    @drums = Drum.all

    render json: @drums
  end

  # GET /drums/1
  def show
    render json: @drum
  end

  # POST /drums
  def create
    @drum = Drum.new(drum_params)

    if @drum.save
      render json: @drum, status: :created, location: @drum
    else
      render json: @drum.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /drums/1
  def update
    if @drum.update(drum_params)
      render json: @drum
    else
      render json: @drum.errors, status: :unprocessable_entity
    end
  end

  # DELETE /drums/1
  def destroy
    @drum.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_drum
      @drum = Drum.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def drum_params
      params.require(:drum).permit(:name)
    end
end

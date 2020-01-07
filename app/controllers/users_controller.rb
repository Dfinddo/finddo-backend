class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:update]
  before_action :set_user, only: [:update]

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      @user.addresses.build(address_params)
      
      token = DeviseTokenAuth::TokenFactory.create

      # store client + token in user's token hash
      @user.tokens[token.client] = {
        token:  token.token_hash,
        expiry: token.expiry
      }

      # generate auth headers for response
      new_auth_header = @user.build_auth_header(token.token, token.client)

      # update response with the header that will be required by the next request
      response.headers.merge!(new_auth_header)

      @user.save
      render json: @user, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def user_params
      params.require(:user)
        .permit(
          :name, :cellphone, 
          :cpf, :user_type, 
          :password, :password_confirmation,
          :email)
    end

    def address_params
      params.require(:address)
        .permit(:cep, :name, :street, :state, :district, :city, :number, :complement)
    end
end

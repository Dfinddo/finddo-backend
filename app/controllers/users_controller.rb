class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :set_user, except: [:create]

  # POST /users
  def create
    @user = User.new(user_params)
    @user.player_ids = params[:player_ids]

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

      # informações de cobrança da Wirecard
      @user.cep = address_params[:cep]
      @user.rua = address_params[:street]
      @user.estado = address_params[:state]
      @user.bairro = address_params[:district]
      @user.cidade = address_params[:city]
      @user.numero = address_params[:number]
      @user.complemento = address_params[:complement]
      # informações de cobrança da Wirecard

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

  def get_profile_photo
    if @user.user_profile_photo
      render json: @user.user_profile_photo
    else
      render json: { photo: nil }
    end
  end

  def set_profile_photo
    @profile_photo = @user.user_profile_photo

    if !@profile_photo
      @profile_photo = UserProfilePhoto.new
    end

    @profile_photo.photo.attach(image_io(params[:profile_photo]))
    @user.user_profile_photo = @profile_photo

    if @user.save
      render json: @profile_photo
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def update_player_id
    @another_user = User.where("player_ids @> ARRAY[?]::varchar[]", [params[:player_id]])
    
    @user.player_ids << params[:player_id] unless @user.player_ids.include? params[:player_id]

    if @another_user.length > 0 && @another_user != @user
      @another_user.first.transaction do
        @another_user.first.player_ids.delete params[:player_id]

        if @another_user.first.save! && @user.save!
          render json: @user, status: :ok
        else
          render json: {error: 'falha ao processar o id'}, status: :unprocessable_entity
        end
      end
      return
    elsif @user.save
      render json: @user, status: :ok
    else
      render json: {error: 'falha ao processar o id'}, status: :unprocessable_entity
    end
  end

  def remove_player_id
    if params[:player_id]
      @user.player_ids.delete params[:player_id]

      if @user.save
        return
      else
        render json: {error: 'falha ao remover o id do dispositivo do usuário'}, status: :unprocessable_entity
      end
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
          :email, :customer_wirecard_id,
          :birthdate, :own_id_wirecard, 
          :player_ids, :surname)
    end

    def address_params
      params.require(:address)
        .permit(:cep, :name, :street, :state, :district, :city, :number, :complement, :selected)
    end

    def image_io(image)
      decoded_image = Base64.decode64(image[:base64])
      { io: StringIO.new(decoded_image), filename: image[:file_name] }
    end
end

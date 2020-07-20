class Api::V2::UsersController < Api::V2::ApiController
  before_action :require_login, except: [:create, :generate_access_token_professional, :get_user]
  before_action :set_user, except: [:create, :get_user, :activate_user]

  # GET /users
  def get_user
    @user = User.find_by(email: params[:email])
    if @user
      render json: { error: 'Já existe um usuário com esse email.' }, status: :forbidden
      return
    else
      @user = User.find_by(cellphone: params[:cellphone])
      if @user
        render json: { error: 'Já existe um usuário com esse telefone.' }, status: :forbidden
        return
      else
        @user = User.find_by(cpf: params[:cpf])
        if @user
          render json: { error: 'Já existe um usuário com esse cpf.' }, status: :forbidden
          return
        else
          render json: {}, status: :ok
        end
      end
    end
  end

  def create
    @user = User.new(user_params)
    @user.player_ids = params[:player_ids]
    @user.activated = true if @user.user_type == "user"

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
      if address_params
        @user.cep = address_params[:cep]
        @user.rua = address_params[:street]
        @user.estado = address_params[:state]
        @user.bairro = address_params[:district]
        @user.cidade = address_params[:city]
        @user.numero = address_params[:number]
        @user.complemento = address_params[:complement]
      end
      # informações de cobrança da Wirecard

      @user.save
      payload = { user_id: user.id }
      token = encode_token(payload)
      render json: { user: @user, jwt: token }, status: :created
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

  def activate_user
    @user = User.find_by(cellphone: params[:cellphone])

    if @user.update(activated: params[:activated])
      head :no_content
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
    if params[:player_id].nil? || params[:player_id].empty? || params[:player_id].length < 10
      render json: { erro: 'Player id inválido' }, status: :bad_request
      return
    end

    @another_users = User.where("player_ids @> ARRAY[?]::varchar[]", [params[:player_id]]).where.not(id: @user.id)
    
    @user.player_ids = [params[:player_id]] unless @user.player_ids.include? params[:player_id]

    if @another_users.length > 0
      User.transaction do
        @another_users.each do |another_user|
          another_user.player_ids.delete params[:player_id]
          
          if !another_user.save!
            render json: {error: 'falha ao processar o id'}, status: :unprocessable_entity
            return
          end
        end
        if @user.save!
            head :no_content
        else
          render json: {error: 'falha ao processar o id'}, status: :unprocessable_entity
        end
      end
    elsif @user.save
      head :no_content
    else
      render json: {error: 'falha ao processar o id'}, status: :unprocessable_entity
    end
  end

  def remove_player_id
    if params[:player_id]
      @user.player_ids.delete params[:player_id]

      if @user.save
        head :no_content
      else
        render json: {error: 'falha ao remover o id do dispositivo do usuário'}, status: :unprocessable_entity
      end
    end
  end

  def generate_access_token_professional
    response = HTTParty.post("#{ENV['WIRECARD_CONNECT_URL']}", {
      body: "client_id=#{ENV['WIRECARD_APP_ID']}&client_secret=#{ENV['WIRECARD_CLIENT_SECRET']}&redirect_uri=#{ENV['WIRECARD_REDIRECT_URI']}&grant_type=authorization_code&code=#{params[:code]}",
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'charset' => 'utf-8',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN'],
      },
      # debug_output: STDOUT
    })

    if response.code == 200
      if @user.update(
        { id_wirecard_account: response["moipAccount"]["id"],
          token_wirecard_account: response["access_token"],
          refresh_token_wirecard_account: response["refresh_token"],
          is_new_wire_account: false
        })

        render json: {status: 'success'}, status: :ok
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    else
      render json: response.body, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user)
      .permit(
        :name, :cellphone, 
        :cpf, :user_type,
        :password, :password_confirmation,
        :email, :customer_wirecard_id,
        :birthdate, :own_id_wirecard,
        :player_ids, :surname, 
        :mothers_name, :id_wirecard_account, 
        :token_wirecard_account, :set_account, 
        :is_new_wire_account, :activated)
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

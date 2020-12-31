class Api::V2::UsersController < Api::V2::ApiController
  before_action :set_services
  before_action :require_login, except: [:create, :generate_access_token_professional, :get_user]
  before_action :set_user, except: [
    :create, :get_user, :activate_user, :add_credit_card,
    :get_customer_credit_card_data, :remove_customer_credit_card_data,
    :find_professional_by_name, :set_player_id]

  # GET /users
  def get_user
    begin
      user_data_invalid = @user_service.valid_user(params)
    rescue ServicesModule::V2::ExceptionsModule::NoParamsException
      head :forbidden
      return
    end

    if user_data_invalid.nil?
      head :ok
    else
      render json: user_data_invalid, status: :forbidden
    end
    
  end

  def create
    begin
      @user = @user_service.create_user(user_params, address_params, params)
      if @user = 400
        render json: {"error": "Error: invalid CPF."}, status: 400
        return 400
      end
      render json: SerializersModule::V2::UserSerializer.new(@user).serializable_hash, status: :created
    rescue ServicesModule::V2::ExceptionsModule::UserException => e
      render json: e.user_errors, status: :unprocessable_entity
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def update
    begin
      @user = @user_service.update_user(@user, user_params)
      render json: SerializersModule::V2::UserSerializer.new(@user).serializable_hash, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::UserException => e
      render json: e.user_errors, status: :unprocessable_entity
    end
  end

  def activate_user
    begin
      @user_service.activate_user(params)
    rescue ServicesModule::V2::ExceptionsModule::UserException => e
      if e.user_errors.nil?
        render json: { erro: e }, status: :not_found
      else
        render json: e.user_errors, status: :unprocessable_entity
      end
    end
  end

  def get_profile_photo
    photo = @user_service.get_profile_photo(@user)

    if !photo.nil?
      render json: photo, status: :ok
    else
      head :no_content
    end
  end

  def set_profile_photo
    begin
      @profile_photo = @user_service.set_profile_photo(@user, params)
      render json: @profile_photo, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::UserException => e
      render json: e.user_errors, status: :unprocessable_entity
    end
  end

  def set_player_id
    player_id = params[:player_id]
    user = session_user
    user_id = user.id
    flag = 0

    try = @user_service.set_player_id(user_id, player_id)
    
    if try == true
        print "=============================== DEU CERTO ==========================="
        player_ids = user.player_ids
        render json: {"player_id": player_id}
        return true
    elsif try == false
        print "=============================== JA TEM PLAYER_ID ==========================="
        
        player_ids = user.player_ids

        #Checa se o player_id recebido está presente no array de player_ids do usuário
        check = player_ids.include?(player_id)

        if check == false
          #Caso esteja
          flag = 1
        end

        if flag == 1
          
          #Este usuário logou em um dispositivo que não está listado no banco de dados e precisa ser incluído atraves de seu player_id.
          user.player_ids << player_id

          if user.save
            render json: {"debug": "Player_id saved."}
            return true
          else
            render json: {"error": "Error: Coudn't append player_id."}
            return 400
          end

        end

        #O player_id recebido já existe para este usuário.
        render json: {"warning": "Player_id found in user's player_ids."}
        return false
    end

    print "=============================== DEU ERRADO ==========================="
    render json: {"error": "Error: Coudn't save player_id."}
    return 400
end

  def update_player_id
    begin
      @user_service.update_player_id(@user, params)
      head :no_content
    rescue ServicesModule::V2::ExceptionsModule::UserException => e
      if e.user_errors
        render json: u.user_errors, status: :unprocessable_entity
      else
        render json: { erro: e }, status: :unprocessable_entity
      end
    end
  end

  def remove_player_id
    begin
      @user_service.remove_player_id(@user, params)
      head :no_content
    rescue ServicesModule::V2::ExceptionsModule::UserException => e
      render json: u.user_errors, status: :unprocessable_entity
    end
  end

  def generate_access_token_professional
    begin
      @user_service.generate_access_token_professional(params)
      head :ok
    rescue ServicesModule::V2::ExceptionsModule::UserException, 
      ServicesModule::V2::ExceptionsModule::PaymentGatewayException => e
      render json: e.errors, status: :unprocessable_entity
    end
  end

  def add_credit_card
    begin
      credit_card = @user_service.add_credit_card_user(params[:credit_card], session_user)
      render json: credit_card, status: :created
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def get_customer_credit_card_data
    begin
      credit_card_data = @user_service.get_customer_credit_card_data(session_user.customer_wirecard_id)
      render json: credit_card_data, status: :ok
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def remove_customer_credit_card_data
    begin
      @user_service.remove_customer_credit_card_data(params[:card_id])
      head :ok
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      render json: e.get_error_object[:error_obj], status: e.get_error_object[:error_status]
    end
  end

  def find_professional_by_name
    result = @user_service.find_professional_by_name(user_params[:name], params[:page])
    result[:items] = result[:items].map { |item| SerializersModule::V2::UserSerializer.new item }

    render json: result
  end

  private

    def set_services
      @user_service = ServicesModule::V2::UserService.new
    end

    def set_user
      @user = @user_service.find_user(params[:id])

      if @user.nil?
        render json: { erro: 'Usuário não encontrado' }, status: :not_found
        return
      end
    end

    def user_params
      params.require(:user)
        .permit(
          :name, :cellphone, 
          :cpf, :user_type,
          :password, :password_confirmation,
          :email, :customer_wirecard_id,
          :birthdate, :own_id_wirecard,
          :surname, :mothers_name, 
          :id_wirecard_account, :token_wirecard_account, 
          :set_account, :is_new_wire_account, 
          :activated, :player_ids => [])
    end

    def address_params
      params.require(:address)
        .permit(:cep, :name, :street, :state, :district, :city, :number, :complement, :selected)
    end
end

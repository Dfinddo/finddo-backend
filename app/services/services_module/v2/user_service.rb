class ServicesModule::V2::UserService < ServicesModule::V2::BaseService
  require "cpf_cnpj"

  def initialize
    @payment_gateway_service = ServicesModule::V2::PaymentGatewayService.new
    @address_service = ServicesModule::V2::AddressService.new
  end

  def find_user(id)
    User.find_by(id: id)
  end

  def valid_user(params)
    if params[:email].nil? && params[:cellphone].nil? && params[:cpf].nil?
      raise ServicesModule::V2::ExceptionsModule::NoParamsException.new
    end

    cpf = params[:cpf]
    user = User.find_by(email: params[:email])
    if user
      return {error: 'Já existe um usuário com esse email.'}

    else
      user = User.find_by(cellphone: params[:cellphone])

      if user
        return {error: 'Já existe um usuário com esse telefone.'}

      else
        user = User.find_by(cpf: cpf)

        if user
          return {error: 'Já existe um usuário com esse cpf.'}

        elsif !CPF.valid?(cpf)
          return {error: 'CPF inválido.'}

        else
          return nil

        end

      end

    end
  end

  def create_user(user_params, address_params, params)
    cpf = user_params[:cpf]
    
    if !CPF.valid?(cpf)
      puts "\n\n\n=== CPF INVÁLUDO ===\n\n\n"
      return 400
    end
      
    User.transaction do
      @user = User.new(user_params)
      @user.activated = true if @user.user_type == "user"

      if @user.save
        if address_params[:name] == nil
          address_params[:name] = "Principal"
        end

        address = @user.addresses.build(address_params)
        
        @address_service.set_selected_address(@user, address)

        if @user.user_type == "user"
          begin
            response = @payment_gateway_service.create_wirecard_customer(@user, address)
            parsed_response = JSON.parse(response.body)
            @user.customer_wirecard_id = parsed_response["id"]
            @user.own_id_wirecard = parsed_response["ownId"]
          rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
            raise e
          end
        elsif @user.user_type == "professional"
          begin
            if !@payment_gateway_service.wirecard_account_exists?(@user.cpf)
              response = @payment_gateway_service.generate_classical_wirecard_account(@user, address)
              parsed_response = JSON.parse(response.body)
              @user.id_wirecard_account = parsed_response["id"]
              @user.set_account = parsed_response["_links"]["setPassword"]["href"]
            end
            @user.is_new_wire_account = true
          rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
            raise e
          end
        else
          raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
            nil, 'tipo usuário inválido', 400
          )
        end

        if @user.save
          @user
        else
          raise ServicesModule::V2::ExceptionsModule::UserException.new(@user.errors)
        end
      else
        raise ServicesModule::V2::ExceptionsModule::UserException.new(@user.errors)
      end
    end
  end

  def update_user(user, user_params)
    if user.update(user_params)
      user
    else
      raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors)
    end
  end

  def activate_user(params)
    @user = User.find_by(cellphone: params[:cellphone])

    raise ServicesModule::V2::ExceptionsModule::UserException.new(nil, "Usuario não encontrado.") if @user.nil?

    if @user.update(activated: params[:activated])
      nil
    else
      raise ServicesModule::V2::ExceptionsModule::UserException.new(@user.errors)
    end
  end

  def get_profile_photo(user)
    if user.user_profile_photo
      user.user_profile_photo
    else
      nil
    end
  end

  def set_profile_photo(user, params)
    @profile_photo = user.user_profile_photo

    if !@profile_photo
      @profile_photo = UserProfilePhoto.new
    end

    @profile_photo.photo.attach(image_io(params[:profile_photo]))
    user.user_profile_photo = @profile_photo

    if user.save
      @profile_photo
    else
      raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors)
    end
  end

  def set_player_id(user_id, player_id)
    user = User.find_by(id: user_id)
  
    if user == nil
      return 400
    end

    player_ids = user.player_ids
  
    if player_ids.length == 0 || player_ids == [nil]
      user.player_ids << player_id
      
      if user.save
        return true
      else
        return 400
      end
      
    end

    return false
  end

  #Ver para que serve
  def update_player_id(user, params)
    if params[:player_id].nil? || params[:player_id].empty? || params[:player_id].length < 10
      raise ServicesModule::V2::ExceptionsModule::UserException.new(nil, "Player id inválido")
    end

    @another_users = User.where("player_ids @> ARRAY[?]::varchar[]", [params[:player_id]]).where.not(id: user.id)
    
    user.player_ids = [params[:player_id]] unless user.player_ids.include? params[:player_id]

    if @another_users.length > 0
      User.transaction do
        @another_users.each do |another_user|
          another_user.player_ids.delete params[:player_id]
          
          if !another_user.save
            raise ServicesModule::V2::ExceptionsModule::UserException.new(another_user.errors, "falha ao processar o usuario #{another_user.id}")
          end
        end
        if !user.save
          raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors, "falha ao processar o usuario #{user.id}")
        end
      end
    elsif !user.save
      raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors, "falha ao processar o usuario #{user.id}")
    end
  end

  def remove_player_id(user, params)
    if params[:player_id]
      user.player_ids.delete params[:player_id]

      if !user.save
        raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors)
      end
    end
  end

  def generate_access_token_professional(params)
    begin
      response = @payment_gateway_service.generate_access_token_professional(params[:code])

      if !@user.update(
        { id_wirecard_account: response["moipAccount"]["id"],
          token_wirecard_account: response["access_token"],
          refresh_token_wirecard_account: response["refresh_token"],
          is_new_wire_account: false
        })
        raise ServicesModule::V2::ExceptionsModule::UserException.new(user.errors)
      end
    rescue ServicesModule::V2::ExceptionsModule::PaymentGatewayException => e
      raise ServicesModule::V2::ExceptionsModule::PaymentGatewayException.new(e.payment_errors)
    end
  end

  def add_credit_card_user(credit_card_data, user)
    begin
      response = @payment_gateway_service.add_credit_card(credit_card_data, user)
      parsed_response = JSON.parse(response.body)
      parsed_response
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      raise e
    end
  end

  def get_customer_credit_card_data(customer_wirecard_id)
    begin
      @payment_gateway_service.get_customer_credit_card_data(customer_wirecard_id)
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      raise e
    end
  end

  def remove_customer_credit_card_data(card_id)
    begin
      @payment_gateway_service.remove_customer_credit_card_data(card_id)
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      raise e
    end
  end

  def find_professional_by_name(name, page)
    page = page || 1
    @users = User
        .includes(:user_profile_photo)
        .where("upper(name) LIKE upper(?)", "%#{name}%")
        .where("user_type = 2")
        .order(name: :asc).page(page)

    { items: @users, current_page: @users.current_page, total_pages: @users.total_pages }
  end

  private

    def image_io(image)
      decoded_image = Base64.decode64(image[:base64])
      { io: StringIO.new(decoded_image), filename: image[:file_name] }
    end
end

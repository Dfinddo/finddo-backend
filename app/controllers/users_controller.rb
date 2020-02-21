class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :set_user, except: [:create]

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
        .permit(:cep, :name, :street, :state, :district, :city, :number, :complement, :selected)
    end

    def image_io(image)
      decoded_image = Base64.decode64(image[:base64])
      { io: StringIO.new(decoded_image), filename: image[:file_name] }
    end
end

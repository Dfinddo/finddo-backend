class Api::V2::AuthController < Api::V2::ApiController
  before_action :set_user_services, only: [:login]

  def login
    user = User.find_by(email: params[:email])
    if user && user.valid_password?(params[:password])
      payload = { user_id: user.id }
      token = encode_token(payload)
      user.update(temporary_token: token)
      user_profile_photo = ServicesModule::V2::UserService.new.get_profile_photo(user)

      if user_profile_photo != nil
        user_profile_photo = UserProfilePhotoSerializer.new(user_profile_photo)
      end

      render json: { user: SerializersModule::V2::UserSerializer.new(user).serializable_hash, jwt: token, photo: user_profile_photo }
    else
      render json: { error: "Log in failed! Username or password invalid!" }, status: :bad_request
    end
  end

  def auto_login
    if session_user
      render json: session_user
    else
      render json: { errors: "No user logged in." }
    end
  end

  private
  def set_user_services
    @user_services = ServicesModule::V2::UserService.new
  end

end

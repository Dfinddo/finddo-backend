class Api::V2::AuthController < Api::V2::ApiController

  def login
    user = User.find_by(email: params[:email])
    if user && user.valid_password?(params[:password])
      payload = { user_id: user.id }
      token = encode_token(payload)
      render json: { user: SerializersModule::V2::UserSerializer.new(user).serializable_hash, jwt: token }
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
end

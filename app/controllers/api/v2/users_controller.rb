class Api::V2::UsersController < Api::V2::ApiController

  def create
    user = User.create(user_params)
    if user.valid?
      payload = { user_id: user.id }
      token = encode_token(payload)
      render json: { user: user, jwt: token }
    else
      render json: { errors: user.errors.full_messages }, status: :bad_request
    end
  end

  private

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
end

class SerializersModule::V2::UserSerializer < SerializersModule::V2::BaseSerializer

  attributes :id, :name, :email, :cellphone, :cpf, :user_type,
  :customer_wirecard_id, :birthdate, :own_id_wirecard,
  :player_ids, :surname, :mothers_name, :id_wirecard_account,
  :token_wirecard_account, :refresh_token_wirecard_account,
  :set_account, :is_new_wire_account, :rate, :activated
end

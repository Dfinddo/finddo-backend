module Api::V2
  class ApiController < ApplicationController
    include ServicesModule::V2
    include SerializersModule::V2

    def encode_token(payload)
      exp = Time.zone.now.to_i + 15 * 24 * 3600 # 15 dias
      payload[:exp] = exp
      JWT.encode(payload, "#{ENV['JWT_SECRET']}")
    end

    def session_user
      decoded_hash = decoded_token
      if !decoded_hash.empty?
        user_id = decoded_hash[0]['user_id']
        if decoded_hash[0]['exp'].to_i >= Time.zone.now.to_i
          @user = User.find_by(id: user_id)
        else
          nil
        end
      else
        nil
      end
    end

    def auth_header
      request.headers['Authorization']
    end

    def decoded_token
      if auth_header
        token = auth_header.split(' ')[1]
        begin
          JWT.decode(token, "#{ENV['JWT_SECRET']}", true, algorithm: 'HS256')
        rescue JWT::DecodeError
          []
        end
      else
        []
      end
    end

    def logged_in?
      !!session_user
    end

    def require_login
      render(json: { error: "Unauthorized access, please log in." }, 
        status: :unauthorized) unless logged_in?
    end
  end
end
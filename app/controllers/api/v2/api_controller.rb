module Api::V2
  class ApiController < ApplicationController
    
    def encode_token(payload)
      exp = Time.zone.now.to_i + 30 * 24 * 3600 # 30 dias
      payload[:exp] = exp
      JWT.encode(payload, 'my_secret') # <= Trocar para variável de ambiente
    end

    def session_user
      decoded_hash = decoded_token
      if !decoded_hash.empty?
        user_id = decoded_hash[0]['user_id']
        @user = User.find_by(id: user_id)
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
          JWT.decode(token, 'my_secret', true, algorithm: 'HS256')
        rescue JWT::DecodeError
          []
        end
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
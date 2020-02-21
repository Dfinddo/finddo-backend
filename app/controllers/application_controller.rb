class ApplicationController < ActionController::API
        include DeviseTokenAuth::Concerns::SetUserByToken
        before_action :configure_permitted_parameters, if: :devise_controller?

        protected

        # TODO: verificar real necessidade desses parâmetros
        def configure_permitted_parameters
                devise_parameter_sanitizer.permit(
                        :sign_up, 
                        keys: [:name, :cellphone, :cpf, :user_type, :email])
                devise_parameter_sanitizer.permit(
                        :account_update, 
                        keys: [:name, :cellphone, :cpf, :user_type, :email, :profile_photo])
        end
end

class Api::V2::NotificationController < Api::V2::ApiController
    before_action :require_login
    before_action :set_services

    #POST notification/send_notification
    def send_notification_with_user_id
        user_id = notification_params[:user_id].to_i
        data = {teste: "teste"}
        render json: data
        return
        content = notification_params[:content]

        try = @notification_service.send_notification_with_user_id(user_id, data, content)

        if try == 400
            render json: {"error": "Error: User doesn't exist."}
            return 400
        elsif try == 401
            render json: {"error": "Error: Notification could not be sent."}
            return 401
        end

        render json: {"notification": notification_params}
        return 200
    end

    
    private
    def notification_params
        params.require(:notification)
          .permit(
              :user_id,
              :data,
              :content)
    end

    def data_params
        params.require(:data)
    end

    def set_services
        @notification_service = ServicesModule::V2::NotificationService.new
    end
end
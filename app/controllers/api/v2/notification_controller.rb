class Api::V2::NotificationController < ApplicationController
    before_action :set_services

    #POST notification
    def send_notification_with_user_id
        user_id = notification_params[:user_id].to_i
        data = notification_params[:data]
        content = notification_params[:content]

        try = @notification_service.send_notification_with_user_id(user_id, data, content)

        if try == 400
            render json: {"error": "Error: Notification could not be sent."}
            return 400
        end

        render json: notification_params
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

    def set_services
        @notification_service = ServicesModule::V2::NotificationService.new
    end
end
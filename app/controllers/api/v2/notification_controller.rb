class Api::V2::NotificationController < ApplicationController
    before_action :set_services

    #POST notification/send_notification
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

    #GET notification/get_player_id?player_id
    def get_player_id
        player_id = params[:player_id]
        user_id = session_user.id
        player_ids = nil

        try = @notification_service.save_player_id(user_id, player_id)

        if try == true
            print "=============================== DEU CERTO ==========================="
            return true
        elsif try == false
            print "=============================== JA TEM PLAYER_ID ==========================="
            player_ids = session_user.player_ids
            #if player_id not in player_ids
                #fazer o append para o novo
            #end 
            return false
        end

        print "=============================== DEU ERRADO ==========================="
        return 400
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
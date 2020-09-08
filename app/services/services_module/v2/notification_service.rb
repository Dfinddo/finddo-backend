class ServicesModule::V2::NotificationService < ServicesModule::V2::BaseService

  def initialize
    @rest_service = ServicesModule::V2::RestService.new
    @onesignal_url = "https://onesignal.com/api/v1/notifications"
  end

  def send_notification(devices = [], data = {}, content = '')
    body = {
      app_id: ENV['ONE_SIGNAL_APP_ID'], 
      include_player_ids: devices,
      data: data,
      contents: { 'en': content }}

    request = @rest_service.post(@onesignal_url, body)

    if request.code == 200
      print "=============================== DEU CERTO ==========================="
      return true
    else
      print "\n #{request.code}"
      print "=============================== DEU ERRADO ==========================="
      return false
    end
  end
end
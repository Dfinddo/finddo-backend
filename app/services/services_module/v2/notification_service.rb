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

  def send_notification_with_user_id(user_id, data, content)
    user = User.find_by(id: user_id)

    if user == nil
      raise ServicesModule::V2::ExceptionsModule::UserException.new(nil, "Usuário não existe.")
    end

    devices = user.player_ids
    
    try = send_notification(devices, data, content)

    if try == true
      #Notificação realizada
      return 200
    else
      #Notificação falhou
      return 400
    end
    
  end

  def send_notification_2(user_id, data = {}, content = '')
    body = {
      app_id: ENV['ONE_SIGNAL_APP_ID'], 
      include_external_user_ids: [user_id],
      Authorization: "Basic YmZhNjc0MzQtMmU4YS00ZjJlLThmODEtMzFmNTVlMmEwNDJm",
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
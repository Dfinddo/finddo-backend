class ServicesModule::V2::PaymentGatewayService < ServicesModule::V2::BaseService

  def initialize
    @rest_service = ServicesModule::V2::RestService.new
  end

  def generate_access_token_professional(code)
    response = @rest_service.post("#{ENV['WIRECARD_CONNECT_URL']}", 
      "client_id=#{ENV['WIRECARD_APP_ID']}&client_secret=#{ENV['WIRECARD_CLIENT_SECRET']}&redirect_uri=#{ENV['WIRECARD_REDIRECT_URI']}&grant_type=authorization_code&code=#{code}",
      {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'charset' => 'utf-8',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN'],
      }
    )
    if response.code == 200
      response
    else
      raise ServicesModule::V2::ExceptionsModule::PaymentGatewayException.new(response.body)
    end
  end
end

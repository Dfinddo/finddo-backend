class ServicesModule::V2::ExceptionsModule::PaymentGatewayException < ServicesModule::V2::ExceptionsModule::BaseException

  def initialize(errors = nil, msg="Falha ao executar operação com gateway de pagamento")
    @errors = errors
    super(errors, msg)
  end

  def payment_errors
    @errors
  end
end

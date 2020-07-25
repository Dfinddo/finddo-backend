class ServicesModule::V2::ExceptionsModule::OrderException < ServicesModule::V2::ExceptionsModule::BaseException

  def initialize(errors = nil, msg="Falha ao executar operação no pedido")
    @errors = errors
    super(errors, msg)
  end

  def order_errors
    @errors
  end
end

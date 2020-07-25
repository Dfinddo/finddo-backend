class ServicesModule::V2::ExceptionsModule::OrderWithProfessionalException < ServicesModule::V2::ExceptionsModule::BaseException

  def initialize(msg="Pedido já possui profissional associado")
    super(msg)
  end
end

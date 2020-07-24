class ServicesModule::V2::ExceptionsModule::NoParamsException < ServicesModule::V2::ExceptionsModule::BaseException

  def initialize(msg="Não foram fornecidos parâmetros para o método")
    super(msg)
  end
end

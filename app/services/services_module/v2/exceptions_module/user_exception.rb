class ServicesModule::V2::ExceptionsModule::UserException < ServicesModule::V2::ExceptionsModule::BaseException

  def initialize(errors = nil, msg="Falha ao executar operação no usuário")
    @errors = errors
    super(errors, msg)
  end

  def user_errors
    @errors
  end
end

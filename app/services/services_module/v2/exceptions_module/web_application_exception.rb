class ServicesModule::V2::ExceptionsModule::WebApplicationException < ServicesModule::V2::ExceptionsModule::BaseException

  attr_reader :status

  # A PARTIR DO COMMIT EM QUE ESSA CLASSE DE ERRO ENTRAR, TODAS AS EXCEÇÕES
  # LEVANTADAS NA APLICAÇÃO DEVEM UTILIZAR ESTA CLASSE
  def initialize(errors = nil, msg="Falha ao executar operação", status=500)
    @status = status
    super(errors, msg)
  end

  def get_error_object
    obj = { error_obj: { message: @msg }, error_status: @status }
    obj[:error_obj][:errors] = @errors if !@errors.nil?
    
    obj
  end
end

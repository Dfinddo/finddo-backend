module ServicesModule::V2::ExceptionsModule
  class BaseException < StandardError

    attr_reader :errors, :msg

    def initialize(errors, msg)
      @msg = msg
      @errors = errors
      super(msg)
    end
  end
end
module ServicesModule::V2::ExceptionsModule
  class BaseException < StandardError

    attr_reader :errors

    def initialize(errors, msg)
      @errors = errors
      super(msg)
    end
  end
end
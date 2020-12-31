class ProfessionalArrivedAtServiceAddressJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ServicesModule::V2::OrderService.new.professional_arrived_at_service_address
  end
end

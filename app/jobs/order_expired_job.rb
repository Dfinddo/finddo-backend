class PrintaOiJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ServicesModule::V2::OrderService.new.expired_orders
    puts "\n\n\n==== funcionou ! ====\n\n\n"
  end
end

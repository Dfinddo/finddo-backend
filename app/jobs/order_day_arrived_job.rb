class OrderDayArrivedJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ServicesModule::V2::OrderService.new.order_day_arrived
    puts "\n\n\n==== order_day_arrived funcionou ! ====\n\n\n"
  end
end

class OneDayEarlierThenOrderDayJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ServicesModule::V2::OrderService.new.one_day_earlier_then_order_day
  end
end

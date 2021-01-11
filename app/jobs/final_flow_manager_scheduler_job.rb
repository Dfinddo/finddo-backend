class FinalFlowManagerSchedulerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    order_id = args[0]
    notification_type = args[1]
    ServicesModule::V2::OrderService.new.final_flow_manager(order_id, notification_type)
  end
end

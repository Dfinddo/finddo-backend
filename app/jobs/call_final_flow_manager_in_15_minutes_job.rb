class CallFinalFlowManagerIn15MinutesJob < ApplicationJob
  queue_as :default

  def perform(*args)
    order_id = args[0][:order_id].to_s
    notification_type = "next calls"
        
    job_name = 'final_flow_manager in 15 minutes for order with id: ' + order_id
    
    Sidekiq.set_schedule(job_name, { 'in' => ['15m'], 'class' => 'FinalFlowManagerSchedulerJob', 'args' => [order_id, notification_type]} )

  end
end

class EnqueueOrdersJob < ApplicationJob
  queue_as :default
  
  def perform(*args)
    order_id = args[0][:order_id]
    start_order = args[0][:start_order]
    notification_type = "first call"
    
    job_name = 'final_flow_manager at: ' + start_order + ' for order with id: ' + order_id.to_s
    
    Sidekiq.set_schedule(job_name, { 'at' => [start_order], 'class' => 'FinalFlowManagerSchedulerJob', 'args' => [order_id, notification_type] } )

  end
end

#Este job agenda um outro job que por sua vez agenda uma função na classe de serviço de orders.

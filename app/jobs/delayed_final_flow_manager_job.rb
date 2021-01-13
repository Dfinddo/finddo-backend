class DelayedFinalFlowManagerJob < ApplicationJob
  queue_as :default

  def perform(*args)
  
    order_id = args[0]
    notification_type = "next calls"
        
    job_name = 'final_flow_manager in 15 minutes for order with id: ' + order_id.to_s
    
    #Precisa ser desativado antes de ativar para que seja feita a recursão
    Sidekiq.set_schedule(job_name, { 'in' => ['15m'], 'class' => 'FinalFlowManagerSchedulerJob', 'args' => [order_id.to_s, notification_type], 'enabled' => false } )
    Sidekiq.set_schedule(job_name, { 'in' => ['15m'], 'class' => 'FinalFlowManagerSchedulerJob', 'args' => [order_id.to_s, notification_type], 'enabled' => true } )

  end
end

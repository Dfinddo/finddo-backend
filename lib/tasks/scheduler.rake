desc "This task is called by the Heroku scheduler add-on"
task :expired_orders => :environment do
  ServicesModule::V2::OrderService.new.expired_orders
end

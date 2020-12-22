desc "This task is called by the Heroku scheduler add-on"
task :expired_orders => :environment do
  Api::V2::OrdersController.new.expired_orders
end

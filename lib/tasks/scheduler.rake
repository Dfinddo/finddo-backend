desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  Api::V2::OrdersController.new.expired_orders
end

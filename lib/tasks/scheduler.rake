desc "This task is called by the Heroku scheduler add-on"
task :Log_in => :environment do
  puts "Logging in."
  Orders
  puts "done."
end

task :send_reminders => :environment do
  User.send_reminders
end

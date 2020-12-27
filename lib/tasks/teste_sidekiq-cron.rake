desc "Testando sideqik cron"
task :teste_sidekiq => :environment do
  PrintaOiJob::perform
end

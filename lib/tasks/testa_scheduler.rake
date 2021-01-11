namespace :testa_scheduler do
  desc "TODO"
  task Testando: :environment do
    time = DateTime.now
    puts "\n\n\n==== %s ====\n\n\n"%time.to_s
    Sidekiq.set_schedule('testando por data', { 'at' => ['2021-01-10 09:20:00'], 'class' => 'TesteJob' })
  end

end

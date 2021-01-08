class TestePorCronJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "\n\n\n==== Funciona por cron !!! ====\n\n\n"
  end
end

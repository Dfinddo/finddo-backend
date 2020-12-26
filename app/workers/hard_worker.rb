class HardWorker
  include Sidekiq::Worker

  def perform(*args)
    puts "\n\n\n\n===funcionou !===\n\n\n\n"
  end
  
  def faz
  	puts "oi"
  end
end

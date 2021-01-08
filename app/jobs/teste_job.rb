class TesteJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "\n\n\n\n=== Funciona por intervalo de tempo !!! ===\n\n\n\n"
  end
end

class PrintaOiJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "====\n\n\n funcionou ! \n\n\n====
  end
end

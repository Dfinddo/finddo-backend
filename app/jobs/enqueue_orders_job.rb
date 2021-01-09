class EnqueueOrdersJob < ApplicationJob
  queue_as :default

  def perform(*args)
    #modifica o sidekiq.yml para incluir a funcao F2 para rodar no dia e hora recebidos como argumento
  end
end

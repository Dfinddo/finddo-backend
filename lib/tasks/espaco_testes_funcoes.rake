namespace :espaco_testes_funcoes do
  desc "Environment for testing of general functions of the application."
  task teste_professional_arrived_at_service_address: :environment do
    ServicesModule::V2::OrderService.new.professional_arrived_at_service_address
  end

end

class OrdersQueue < ApplicationRecord
  belongs_to :order, :class_name => 'Order'
  
  enum order_status: [
    :analise, :a_caminho, 
    :em_servico, :finalizado, 
    :cancelado, :processando_pagamento, 
    :recusado, :orcamento_previo,
    :aguardando_profissional, :agendando_visita, :expirado, :aguardando_dia_servico, :classificando]
    
end

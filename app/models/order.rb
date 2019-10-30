class Order < ApplicationRecord
  belongs_to :category
  belongs_to :user
  belongs_to :professional_order, 
    class_name: "User", optional: true, 
    foreign_key: :professional

  enum order_status: [:analise, :agendando_visita, :a_caminho, :em_servico, :finalizado]
end

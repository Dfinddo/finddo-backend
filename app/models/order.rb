class Order < ApplicationRecord
  has_many_attached :images, dependent: :destroy
  has_one :budget, dependent: :destroy

  belongs_to :category
  belongs_to :user
  belongs_to :professional_order, 
    class_name: "User", optional: true, 
    foreign_key: :professional
  belongs_to :address

  # :em_servico será o status quando o profissional só fizer a visita e tiver que retornar
  # atenção ao editar valores, pois é um enum ordinal
  enum order_status: [
    :analise, :a_caminho, 
    :em_servico, :finalizado, 
    :cancelado, :processando_pagamento, 
    :recusado, :orcamento_previo,
    :aguardando_profissional]

  enum urgency: [:urgent, :delayable]

  validates :price, numericality:  { greater_than_or_equal_to: 0 }
end

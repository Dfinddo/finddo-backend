class Order < ApplicationRecord
  has_many_attached :images
  has_one :budget, dependent: :destroy

  belongs_to :category
  belongs_to :user
  belongs_to :professional_order, 
    class_name: "User", optional: true, 
    foreign_key: :professional
  belongs_to :address

  # :em_servico será o status quando o profissional só fizer a visita e tiver que retornar
  enum order_status: [
    :analise, :a_caminho, 
    :em_servico, :finalizado, 
    :cancelado, :processando_pagamento, 
    :recusado]

  enum urgency: [:urgent, :not_urgent]

  validates :price, numericality:  { greater_than_or_equal_to: 0 }
end

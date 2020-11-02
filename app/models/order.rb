class Order < ApplicationRecord
  has_many_attached :images, dependent: :destroy
  has_one :budget, dependent: :destroy
  has_one :rescheduling, dependent: :destroy

  belongs_to :category
  belongs_to :user
  belongs_to :professional_order, :class_name => 'User', :foreign_key => 'professional' #profissional que pegou a order.
  belongs_to :selected_professional, :class_name => 'User' #para o filtro de profissionais.
  belongs_to :order_chat, :class_name => 'Chat' #chat que faz referencia a um servico
  belongs_to :address

  # ordem dos passos sucedidos do pedido:
  # analise, orcamento_previo, agendando_visita,
  # aguardando_profissional, a_caminho,
  # em_servico, finalizado (em qualquer momento se pode cancelar também)

  # :em_servico será o status quando o profissional só fizer a visita e tiver que retornar
  # atenção ao editar valores, pois é um enum ordinal
  enum order_status: [
    :analise, :a_caminho, 
    :em_servico, :finalizado, 
    :cancelado, :processando_pagamento, 
    :recusado, :orcamento_previo,
    :aguardando_profissional, :agendando_visita]

  enum urgency: [:urgent, :delayable]

  validates :price, numericality:  { greater_than_or_equal_to: 0 }
  validate  :previous_budget_value_if_previous_budget

  private

  def previous_budget_value_if_previous_budget
    if previous_budget && previous_budget_value.nil?
      errors.add(:previous_budget_value, "deve estar definido se previous_budget é true")
    end
  end
end

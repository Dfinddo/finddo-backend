class ReschedulingSerializer < ActiveModel::Serializer
  attributes :date_order, :hora_inicio, 
    :hora_fim, :user_accepted, :professional_accepted

  has_one :order
end
class OrderSerializer < ActiveModel::Serializer
  attributes :id, :description, :order_status
  has_one :category
  has_one :professional_order
  has_one :user
end

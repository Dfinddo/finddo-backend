class OrderSerializer < ActiveModel::Serializer
  attributes :id, :description, :order_status,
    :start_order, :end_order, :price, :paid
  has_one :category
  has_one :professional_order
  has_one :user
  has_one :address
end

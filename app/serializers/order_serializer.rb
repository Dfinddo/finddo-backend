class OrderSerializer < ActiveModel::Serializer
  attributes :id, :description
  has_one :category
end

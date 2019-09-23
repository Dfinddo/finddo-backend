class CategorySerializer < ActiveModel::Serializer
  attributes :id, :name
  has_many :subcategories
  has_many :orders
end

class AddressSerializer < ActiveModel::Serializer
  attributes :id, :name, :street, :number, :complement, :cep, :district
  has_one :user
end

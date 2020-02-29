class AddressSerializer < ActiveModel::Serializer
  attributes :id, :name, :street, :number, :complement, :cep, :district, :selected
end

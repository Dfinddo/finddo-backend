class OrderSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :description, :order_status,
    :start_order, :end_order, :price, :paid, :images

  has_one :category
  has_one :professional_order
  has_one :user
  has_one :address

  def images
    return rails_blob_path(object.images, only_path: true)
  end
end

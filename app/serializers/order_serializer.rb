class OrderSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :description, :order_status,
    :start_order, :end_order, :price, :paid, :images, :urgency

  has_one :category
  has_one :professional_order
  has_one :user
  has_one :address

  def images
    urls = []
    
    object.images.each do |image|
      urls << rails_blob_path(image, only_path: true)
    end
    
    urls
  end
end

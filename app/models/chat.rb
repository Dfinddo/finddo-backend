class Chat < ApplicationRecord
  belongs_to :sender, :class_name => 'User'
  belongs_to :receiver, :class_name => 'User'
  belongs_to :order, :class_name => 'Order'

  enum for_admin: ["normal", "user", "professional"]
end

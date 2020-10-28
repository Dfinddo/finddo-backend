class AddOrderReferenceToChats < ActiveRecord::Migration[6.0]
  def change
    add_reference :chats, :order, null: true, foreign_key: true
  end
end

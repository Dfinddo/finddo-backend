class AddWirecardIdsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :order_wirecard_own_id, :string
    add_column :orders, :order_wirecard_id, :string
  end
end

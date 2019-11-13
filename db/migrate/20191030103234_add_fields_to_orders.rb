class AddFieldsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :order_status, :integer, default: 0
    add_column :orders, :professional, :integer
    add_column :orders, :start_order, :datetime
    add_column :orders, :end_order, :datetime
  end
end

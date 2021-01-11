class RemoveOrderStatusFromOrdesQueue < ActiveRecord::Migration[6.0]
  def up
    remove_column :orders_queues, :order_status
  end
  
  def down
    add_column :orders_queues, :order_status, :integer, null: false, default: 0
  end
end

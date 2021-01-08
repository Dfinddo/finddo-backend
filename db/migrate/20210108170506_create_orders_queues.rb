class CreateOrdersQueues < ActiveRecord::Migration[6.0]
  def up
    create_table :orders_queues, id: false do |t|
	  t.references :order, null: false, foreign_key: { to_table: 'orders' }
	  t.integer :order_status, null: false, default: 0
      t.timestamps
    end
    
    
  end
  
  def down
    drop_table :orders_queues
  end
  
end

class AddPrimaryKeyToOrdersQueue < ActiveRecord::Migration[6.0]
  def up
    execute "ALTER TABLE orders_queues ADD PRIMARY KEY (order_id);"
  end
  
  def down
    execute "ALTER TABLE orders_queues DROP CONSTRAINT orders_queues_pkey;"
  end
end

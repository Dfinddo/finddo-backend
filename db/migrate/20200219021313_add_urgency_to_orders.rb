class AddUrgencyToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :urgency, :integer, default: 1
  end
end

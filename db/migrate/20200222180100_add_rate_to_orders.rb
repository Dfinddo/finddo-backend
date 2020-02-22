class AddRateToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :rate, :decimal, precision: 2, scale: 1, default: 0
  end
end

class AddUserRateToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :user_rate, :decimal, precision: 2, scale: 1, default: 0
  end
end

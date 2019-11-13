class AddPriceToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :price, :integer, null: false, default: 0
    add_column :orders, :paid, :boolean, null: false, default: false
  end
end

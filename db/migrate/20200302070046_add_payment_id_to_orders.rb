class AddPaymentIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :payment_wirecard_id, :string
  end
end

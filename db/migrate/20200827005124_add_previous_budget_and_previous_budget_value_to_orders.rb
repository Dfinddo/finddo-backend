class AddPreviousBudgetAndPreviousBudgetValueToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :previous_budget, :boolean, default: false
    add_column :orders, :previous_budget_value, :bigint
  end
end

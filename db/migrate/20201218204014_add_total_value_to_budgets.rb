class AddTotalValueToBudgets < ActiveRecord::Migration[6.0]
  def up
    add_column :budgets, :total_value, :integer, default: 0, null: false
  end
  
  def down
    remove_column :budgets, :total_value
  end
end

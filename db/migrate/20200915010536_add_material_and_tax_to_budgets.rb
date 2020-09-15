class AddMaterialAndTaxToBudgets < ActiveRecord::Migration[6.0]
  def change
    remove_column :budgets, :budget
    add_column :budgets, :material_value, :bigint
    add_column :budgets, :tax_value, :bigint
    add_column :budgets, :value_with_tax, :bigint
    add_column :budgets, :budget, :bigint
  end
end

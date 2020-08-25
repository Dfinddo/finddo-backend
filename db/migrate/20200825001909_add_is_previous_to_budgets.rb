class AddIsPreviousToBudgets < ActiveRecord::Migration[6.0]
  def change
    add_column :budgets, :is_previous, :boolean, default: false
  end
end

class AddProblemSolvedToOrders < ActiveRecord::Migration[6.0]
  def up
    add_column :orders, :problem_solved, :boolean, default: false, null: false 
  end
  def down
    remove_column :orders, :problem_solved
  end
end

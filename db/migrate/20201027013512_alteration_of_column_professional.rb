class AlterationOfColumnProfessional < ActiveRecord::Migration[6.0]
  def up
    rename_column :orders, :professional, :professional_order_id
    change_column :orders, :professional_order_id, :bigint
    add_foreign_key :orders, :users, column: :professional_order_id
    change_column_null :orders, :professional_order_id, :false
  end
  
  def down
    remove_foreign_key :orders, column: :professional_order_id
    rename_column :orders, :professional_order_id, :professional
    change_column :orders, :professional_order_id, :integer
    change_column_null :orders, :professional_order_id, :true
  end
end

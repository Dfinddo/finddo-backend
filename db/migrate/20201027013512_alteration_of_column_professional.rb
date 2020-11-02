class AlterationOfColumnProfessional < ActiveRecord::Migration[6.0]
  def up
    #rename_column :orders, :professional, :professional_order_id
    change_column :orders, :professional, :bigint
    add_foreign_key :orders, :users, column: :professional
    change_column_null :orders, :professional, :false
  end
  
  def down
    rename_column :orders, :professional_order_id, :professional
    change_column_null :orders, :professional, :true
    remove_foreign_key :orders, column: :professional
    change_column :orders, :professional, :integer
    #rename_column :orders, :professional_order_id, :professional
  end
end

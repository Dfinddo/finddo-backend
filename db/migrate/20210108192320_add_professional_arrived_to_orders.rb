class AddProfessionalArrivedToOrders < ActiveRecord::Migration[6.0]
  def up
    add_column :orders, :professional_arrived, :datetime, null: true
  end
  
  def down
    remove_column :orders, :professional_arrived
  end
end

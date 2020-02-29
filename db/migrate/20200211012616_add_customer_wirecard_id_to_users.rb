class AddCustomerWirecardIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :customer_wirecard_id, :string
  end
end

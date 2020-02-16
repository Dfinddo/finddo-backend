class AddImagesToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :images, :string
  end
end

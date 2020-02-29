class AddImagesToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :images, :string, array: true, default: []
  end
end

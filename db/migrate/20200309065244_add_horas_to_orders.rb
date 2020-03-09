class AddHorasToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :hora_inicio, :string
    add_column :orders, :hora_fim, :string
  end
end

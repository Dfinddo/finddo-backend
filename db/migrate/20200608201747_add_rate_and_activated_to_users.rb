class AddRateAndActivatedToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :rate, :decimal, precision: 2, scale: 1, default: 0
    add_column :users, :activated, :boolean, default: false
  end
end

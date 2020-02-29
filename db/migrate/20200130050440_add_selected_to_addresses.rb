class AddSelectedToAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :selected, :boolean, null: false, default: false
  end
end

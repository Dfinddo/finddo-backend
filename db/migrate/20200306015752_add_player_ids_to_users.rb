class AddPlayerIdsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :player_ids, :string, array: true, default: []
  end
end

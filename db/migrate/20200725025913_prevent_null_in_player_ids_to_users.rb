class PreventNullInPlayerIdsToUsers < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:users, :player_ids, false)
  end
end

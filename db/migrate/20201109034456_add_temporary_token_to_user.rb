class AddTemporaryTokenToUser < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :temporary_token, :text
  end
  def down
    remove_column :users, :temporary_token
  end
end

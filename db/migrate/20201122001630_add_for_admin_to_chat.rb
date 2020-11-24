class AddForAdminToChat < ActiveRecord::Migration[6.0]
  def up
    add_column :chats, :for_admin, :integer, default: 0, null: false 
  end
  def down
    remove_column :chats, :for_admin
  end
end

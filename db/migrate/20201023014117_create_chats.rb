class CreateChats < ActiveRecord::Migration[6.0]
  def change
    create_table :chats do |t|
      t.text :message
      t.boolean :is_read, default: false, null: false
      t.references :sender, null: false, foreign_key: { to_table: 'users' }
      t.references :receiver, null: false, foreign_key: { to_table: 'users' }

      t.timestamps
    end
  end
end

class AddSurnameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :surname, :string
    add_column :users, :mothers_name, :string
    add_column :users, :id_wirecard_account, :string, default: nil
    add_column :users, :token_wirecard_account, :string, default: nil
    add_column :users, :refresh_token_wirecard_account, :string, default: nil
  end
end

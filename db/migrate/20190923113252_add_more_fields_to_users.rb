class AddMoreFieldsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :cep, :string
    add_column :users, :cidade, :string
    add_column :users, :complemento, :string
    add_column :users, :estado, :string
    add_column :users, :numero, :string
    add_column :users, :rua, :string
  end
end

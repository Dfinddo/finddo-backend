class AddBairroToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :bairro, :string
  end
end

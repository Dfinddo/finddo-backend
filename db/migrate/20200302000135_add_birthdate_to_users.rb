class AddBirthdateToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :birthdate, :string
    add_column :users, :own_id_wirecard, :string
  end
end

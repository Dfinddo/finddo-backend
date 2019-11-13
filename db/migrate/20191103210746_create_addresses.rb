class CreateAddresses < ActiveRecord::Migration[5.2]
  def change
    create_table :addresses do |t|
      t.string :name
      t.string :street
      t.string :number
      t.string :complement
      t.string :cep
      t.string :district
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end

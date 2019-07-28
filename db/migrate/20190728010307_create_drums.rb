class CreateDrums < ActiveRecord::Migration[5.2]
  def change
    create_table :drums do |t|
      t.string :name

      t.timestamps
    end
  end
end

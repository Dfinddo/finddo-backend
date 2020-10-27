class AlterationOfColumnProfessional < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :professional
    add_reference :orders, :professional_order, null: false, foreign_key: { to_table: 'users' }
  end
end

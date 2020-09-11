class CreateReschedulings < ActiveRecord::Migration[6.0]
  def change
    create_table :reschedulings do |t|
      t.datetime :date_order
      t.string :hora_inicio
      t.string :hora_fim
      t.references :order, null: false, foreign_key: true
      t.boolean :user_accepted, null: true, default: nil
      t.boolean :professional_accepted, null: true, default: nil

      t.timestamps
    end
  end
end

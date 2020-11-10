class ChangeColumnNameOrfers < ActiveRecord::Migration[6.0]
  def up
    rename_column :orders, :selected_professional_id, :filtered_professional_id
  end
  
  def down
    rename_column :orders, :filtered_professional_id, :selected_professional_id
  end
end

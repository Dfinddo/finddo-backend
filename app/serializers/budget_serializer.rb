class BudgetSerializer < ActiveModel::Serializer
  attributes :id, :budget, :accepted, :is_previous,
    :material_value, :value_with_tax, :total_value

  has_one :order
end
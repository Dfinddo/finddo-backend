class BudgetSerializer < ActiveModel::Serializer
  attributes :id, :budget, :accepted, :is_previous

  has_one :order
end
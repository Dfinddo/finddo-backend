class BudgetSerializer < ActiveModel::Serializer
  attributes :id, :budget, :accepted

  has_one :order
end
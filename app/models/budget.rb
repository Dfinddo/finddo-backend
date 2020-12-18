class Budget < ApplicationRecord
  belongs_to :order

  #attr_accessor :total_value
end

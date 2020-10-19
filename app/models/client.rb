class Client < ApplicationRecord
    has_many :documents, dependent: :destroy
end

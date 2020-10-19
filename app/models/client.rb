class Client < ApplicationRecord
    has_many :documents, dependent: :destroy

    before_save :increment_rate

    validates :name, uniqueness: true

    def increment_rate
        self.rate += 1
    end
end

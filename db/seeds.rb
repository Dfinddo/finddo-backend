require 'faker'
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.create(name: 'Admin', email: 'admin@finddo.com.br', password: 'Finddo2019@', password_confirmation: 'Finddo2019@', user_type: :admin)

3.times do |i|
    Category.create(name: Faker::Name.name)
end

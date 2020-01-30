require 'faker'
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
u = User.find_by(email: 'admin@finddo.com.br')
if !u
    User.create(name: 'Admin', email: 'admin@finddo.com.br', password: 'Finddo2019@', password_confirmation: 'Finddo2019@', user_type: :admin)
end

u = User.find_by(email: 'teste@email.com')
if !u
    u = User.create(name: 'Admin', email: 'teste@email.com', password: '12345678', password_confirmation: '12345678', user_type: :user, cellphone: '980808080', cpf: '12345678900')
    10.times do |a|
        Address.create(
            name: Faker::Address.city_prefix, street: Faker::Address.street_name,
            complement: Faker::Address.secondary_address, cep: Faker::Address.zip_code,
            district: Faker::Address.community, user_id: u.id,
            city: 'Rio de Janeiro', state: 'RJ', number: rand(1..100)
        )
    end
end

Category.destroy_all
Category.create(id: 1, name: 'Hidráulica')
Category.create(id: 2, name: 'Elétrica')
Category.create(id: 3, name: 'Pintura')
Category.create(id: 4, name: 'Ar condicionado')
Category.create(id: 5, name: 'Instalações')
Category.create(id: 6, name: 'Pequenas reformas')
Category.create(id: 7, name: 'Consertos em geral')

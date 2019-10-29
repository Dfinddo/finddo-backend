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

Category.destroy_all
Category.create(id: 1, name: 'Hidráulica')
Category.create(id: 2, name: 'Elétrica')
Category.create(id: 3, name: 'Pintura')
Category.create(id: 4, name: 'Ar condicionado')
Category.create(id: 5, name: 'Instalações')
Category.create(id: 6, name: 'Pequenas reformas')
Category.create(id: 7, name: 'Consertos em geral')

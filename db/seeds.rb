# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "I am about to Seed"

Staff.create(name: 'Stephanie', role: 'Photographer')
Staff.create(name: 'Stephanie', role: 'Editor')
Staff.create(name: 'Lara', role: 'Editor')
Staff.create(name: 'Lara', role: 'Photographer')
Staff.create(name: 'Faith', role: 'Photographer')
Staff.create(name: 'Faith', role: 'Editor')
Staff.create(name: 'Sunday', role: 'Editor')
Staff.create(name: 'Peter', role: 'Editor')
Staff.create(name: 'Yusuf', role: 'Editor')
Staff.create(name: 'Samuel', role: 'Editor')
Staff.create(name: 'Frank', role: 'Editor')
Staff.create(name: 'Joy', role: 'Customer Service')
Staff.create(name: 'Ridwan', role: 'Customer Service')
Staff.create(name: 'David', role: 'Customer Service')
Staff.create(name: 'Amaka', role: 'Customer Service')
Staff.create(name: 'Ope', role: 'Customer Service')
Staff.create(name: 'Ebube', role: 'Customer Service')
Staff.create(name: 'Freeman', role: 'Photographer')
Staff.create(name: 'Lanre', role: 'Photographer')
Staff.create(name: 'Micheal', role: 'Photographer')
Staff.create(name: 'Rebecca', role: 'Photographer')
Staff.create(name: 'Deborah', role: 'Photographer')
Staff.create(name: 'Ademola', role: 'Photographer')
Staff.create(name: 'Sam', role: 'Photographer')
Staff.create(name: 'Ernest', role: 'Photographer')

puts "I am done creating all staffs"

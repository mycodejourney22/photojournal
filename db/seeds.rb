# # This file should ensure the existence of records required to run the application in every environment (production,
# # development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# # The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
# #
# # Example:
# #
# #   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
# #     MovieGenre.find_or_create_by!(name: genre_name)
# #   end
# require 'csv'
# require 'date'
# require 'securerandom'
# puts "I am about to Seed"

# file_path = "/mnt/c/Users/yk113/Downloads/data.csv"
# number = 0

# CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
#   number += 1
#   appointment_uuid = SecureRandom.uuid

#   # Create the Appointment
#   puts row.inspect

#   # Parse date format MM/DD/YYYY
#   begin
#     start_time = Date.strptime(row[:date], '%m/%d/%Y')
#   rescue ArgumentError => e
#     puts "Invalid date format: #{row[:date]}"
#     next  # Skip to the next row if date format is invalid
#   end
#   appointment = Appointment.create!(
#     start_time: start_time.to_datetime,
#     location: row[:branch],
#     name: "#{row[:customer_firstname]} #{row[:customer_lastname]}",
#     uuid: appointment_uuid
#   )

#   puts " I have created appointments"
#   # Find the staff members
#   photographer = Staff.find_by(name: row[:photographer])
#   editor = Staff.find_by(name: row[:editor])
#   customer_service = Staff.find_by(name: row[:cso])

#   # Create the PhotoShoot
#   PhotoShoot.create!(
#     appointment: appointment,
#     photographer_id: photographer&.id,
#     editor_id: editor&.id,
#     customer_service_id: customer_service&.id,
#     date: start_time.to_date,
#     number_of_selections: row[:selected_pics_no],
#     status: row[:status],
#     date_sent: row[:date_sent],
#     type_of_shoot: row[:type],
#     number_of_outfits: row[:no_of_outfit],
#     payment_total: row[:amount],
#     reference: row[:reference],
#     payment_method: row[:payment_method],
#     payment_type: row[:payment_type]
#   )
#   puts "I have created #{number} photoshoots"
# end

# puts "I am done creating all Photoshoots"

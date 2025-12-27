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

# Sale.destroy_all
# PhotoShoot.destroy_all
# Appointment.destroy_all

# puts "Deleted all previous instance"

# require 'csv'
# require 'aws-sdk-s3'

# s3_client = Aws::S3::Client.new(
#   region: ENV['AWS_REGION'],
#   access_key_id: ENV['AWS_ACCESS_KEY_ID'],
#   secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
# )

# bucket_name = 'photograhydata'
# object_key = 'data.csv'
# local_file_path = 'data.csv'
# File.open(local_file_path, 'wb') do |file|
#   s3_client.get_object({ bucket: bucket_name, key: object_key }, target: file)
# end


# # csv_object = s3_client.get_object(bucket: bucket_name, key: object_key)
# # csv_content = csv_object.body.read

# # file_path = "/mnt/c/Users/yk113/Downloads/data.csv"
# number = 0

# CSV.foreach(local_file_path, headers: true, header_converters: :symbol) do |row|
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

  # puts "I have created appointment"

  # # Find the staff members
  # photographer = Staff.find_by(name: row[:photographer])
  # editor = Staff.find_by(name: row[:editor])
  # customer_service = Staff.find_by(name: row[:cso])

  # Create the PhotoShoot
  # photoshoot = PhotoShoot.create!(
  #   appointment: appointment,
  #   photographer_id: photographer&.id,
  #   editor_id: editor&.id,
  #   customer_service_id: customer_service&.id,
  #   date: start_time.to_date,
  #   number_of_selections: row[:selected_pics_no],
  #   status: row[:status],
  #   date_sent: row[:date_sent],
  #   type_of_shoot: row[:type],
  #   number_of_outfits: row[:no_of_outfit],
  #   payment_total: row[:amount],
  #   reference: row[:reference],
  #   payment_method: row[:payment_method],
  #   payment_type: row[:payment_type]
  # )

#   puts "I have created #{number} photoshoots"

#   # Create the Sale
#   Sale.create!(
#     date: start_time.to_datetime,
#     amount_paid: row[:amount],
#     payment_method: row[:payment_method],
#     payment_type: row[:payment_type],
#     customer_name: "#{row[:customer_firstname]} #{row[:customer_lastname]}",
#     customer_phone_number: row[:customer_phone_number],
#     customer_service_officer_name: row[:cso],
#     product_service_name: row[:type],
#     location: appointment.location,
#     photo_shoot_id: photoshoot.id
#   )

#   puts "I have created #{number} sales"
# end

# puts "I am done creating all Photoshoots and Sales"

puts "I am starting to create pricing....."
Price.create!([
  { name: "Kiddies", outfit: "1 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    amount: 32500.00, discount: 0, duration: 45, included: "5",
    shoot_type: "Kiddies", still_valid: true, icon: "fa-baby" },
  { name: "Kiddies", outfit: "2 Outfit", description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
    amount: 60000.00, discount: 0, duration: 30, included: "8 Soft Copies", shoot_type: "Kiddies",
    still_valid: true, icon: "fa-baby" },
  { name: "Kiddies", outfit: "3 Outfit", description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
    amount: 90000.00, discount: 0, duration: 30, included: "12 Soft Copies", shoot_type: "Kiddies",
    still_valid: true, icon: "fa-baby" },
  { name: "Kiddies", outfit: "4 Outfit", description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
    amount: 120000.00, discount: 0, duration: 30, included: "15 Soft Copies", shoot_type: "Kiddies",
    still_valid: true, icon: "fa-baby" },
  { name: "Kiddies", outfit: "5 Outfit", description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
    amount: 150000.00, discount: 0, duration: 30, included: "18 Soft Copies", shoot_type: "Kiddies",
    still_valid: true, icon: "fa-baby" },

  { name: "Christmas Kiddies", outfit: "1 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
      amount: 60000.00, discount: 0, duration: 45, included: "5",
      shoot_type: "Christmas Kiddies", still_valid: true, icon: "fa-candy-cane" },
    { name: "Christmas Kiddies", outfit: "2 Outfit", description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
      amount: 90000.00, discount: 0, duration: 30, included: "8 Soft Copies", shoot_type: "Christmas Kiddies",
      still_valid: true, icon: "fa-candy-cane" },
    { name: "Christmas Kiddies", outfit: "3 Outfit", description: "This session is designed for one person, with the option for family or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
      amount: 125000.00, discount: 0, duration: 30, included: "12 Soft Copies", shoot_type: "Christmas Kiddies",
      still_valid: true, icon: "fa-candy-cane" },

    # { name: "Christmas Family", outfit: "1 Outfit", description: "This shoot accommodates up to a 5-person family. For larger families, please contact the studio directly to book. Studio props are available, but additional props must be brought in.",
    #   amount: 75000.00, discount: 0, duration: 30, included: "5 Soft Copies", shoot_type: "Christmas Family",
    #   still_valid: true, icon: "fa-people-group" },
    # { name: "Christmas Family", outfit: "2 Outfit", description: "This shoot accommodates up to a 5-person family. For larger families, please contact the studio directly to book. Studio props are available, but additional props must be brought in.",
    #   amount: 100000.00, discount: 0, duration: 30, included: "8 Soft Copies", shoot_type: "Christmas Family",
    #   still_valid: true, icon: "fa-people-group" },
    # { name: "Christmas Family", outfit: "3 Outfit", description: "This shoot accommodates up to a 5-person family. For larger families, please contact the studio directly to book. Studio props are available, but additional props must be brought in.",
    #     amount: 130000.00, discount: 0, duration: 30, included: "12 Soft Copies", shoot_type: "Christmas Family",
    #     still_valid: true, icon: "fa-people-group" }

    # { name: "Christmas Personal", outfit: "1 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    #   amount: 55000.00, discount: 0, duration: 30, included: "5 Soft Copies", shoot_type: "Christmas Personal",
    #   still_valid: true, icon: "fa-portrait" },
    # { name: "Christmas Personal", outfit: "2 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    #   amount: 85000.00, discount: 0, duration: 30, included: "8 Soft Copies", shoot_type: "Christmas Personal",
    #   still_valid: true, icon: "fa-portrait" },
    # { name: "Christmas Personal", outfit: "3 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    #     amount: 105000.00, discount: 0, duration: 30, included: "12 Soft Copies", shoot_type: "Christmas Personal",
    #     still_valid: true, icon: "fa-portrait" }

  { name: "Personal", outfit: "1 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    amount: 30000.00, discount: 0, duration: 45, included: "5", shoot_type: "Personal",
    still_valid: true, icon: "fa-person-through-window" },
  { name: "Personal", outfit: "2 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    amount: 52500.00, discount: 0, duration: 30, included: "5 Soft Copies", shoot_type: "Personal",
    still_valid: true, icon: "fa-person-through-window"},
  { name: "Personal", outfit: "3 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    amount: 78750.00, discount: 0, duration: 45, included: "12 Soft Copies", shoot_type: "Personal",
    still_valid: true, icon: "fa-person-through-window" },
  { name: "Personal", outfit: "4 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    amount: 105000.00, discount: 0, duration: 30, included: "15 Soft Copies", shoot_type: "Personal",
    still_valid: true, icon: "fa-person-through-window"},
  { name: "Personal", outfit: "5 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    amount: 131500.00, discount: 0, duration: 45, included: "18 Soft Copies", shoot_type: "Personal",
    still_valid: true, icon: "fa-person-through-window" },

  { name: "Family", outfit: "1 Outfit", description: "This shoot accommodates up to a 5-person family. For larger families, please contact the studio directly to book. Studio props are available, but additional props must be brought in.",
    amount: 32500.00, discount: 0, duration: 45, included: "5",
    shoot_type: "Family", still_valid: true, icon: "fa-people-group" },
  { name: "Family", outfit: "2 Outfit", description: "This shoot accommodates up to a 5-person family. For larger families, please contact the studio directly to book. Studio props are available, but additional props must be brought in.",
    amount: 60000.00, discount: 0, duration: 30, included: "8 Soft Copies", shoot_type: "Family",
    still_valid: true, icon: "fa-people-group" },
  { name: "Family", outfit: "3 Outfit", description: "This shoot accommodates up to a 5-person family. For larger families, please contact the studio directly to book. Studio props are available, but additional props must be brought in.",
    amount: 90000.00, discount: 0, duration: 30, included: "12 Soft Copies", shoot_type: "Family",
    still_valid: true, icon: "fa-people-group" },
  { name: "Family", outfit: "4 Outfit", description: "This shoot accommodates up to a 5-person family. For larger families, please contact the studio directly to book. Studio props are available, but additional props must be brought in.",
    amount: 120000.00, discount: 0, duration: 30, included: "15 Soft Copies", shoot_type: "Family",
    still_valid: true, icon: "fa-people-group" },
  { name: "Family", outfit: "5 Outfit", description: "This shoot accommodates up to a 5-person family. For larger families, please contact the studio directly to book. Studio props are available, but additional props must be brought in.",
    amount: 150000.00, discount: 0, duration: 30, included: "18 Soft Copies", shoot_type: "Family",
    still_valid: true, icon: "fa-people-group" },

  { name: "Newborn", outfit: "1 Outfit", description: "We provide baby wraps, furs, and studio props. If you need additional or different items, please bring them with you.",
    amount: 40000.00, discount: 0, duration: 45, included: "5 Soft Copies", shoot_type: "Newborn",
    still_valid: true, icon: "fa-person-breastfeeding" },
  { name: "Newborn", outfit: "2 Outfit", description: "We provide baby wraps, furs, and studio props. If you need additional or different items, please bring them with you.",
    amount: 75000.00, discount: 0, duration: 30, included: "8 Soft Copies", shoot_type: "Newborn",
    still_valid: true, icon: "fa-person-breastfeeding" },
  { name: "Newborn", outfit: "3 Outfit", description: "We provide baby wraps, furs, and studio props. If you need additional or different items, please bring them with you.",
    amount: 105000.00, discount: 0, duration: 30, included: "5 Soft Copies", shoot_type: "Newborn",
    still_valid: true, icon: "fa-person-breastfeeding" },

  { name: "Maternity", outfit: "1 Outfit", description: "This shoot is designed for one person. Studio props are available, but you’ll need to bring any additional props.",
    amount: 32500.00, discount: 0, duration: 45, included: "5 Soft Copies", shoot_type: "Maternity",
    still_valid: true, icon: "fa-person-pregnant" },
  { name: "Maternity", outfit: "2 Outfit", description: "This session is designed for one person, with the option for partner or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
    amount: 60000.00, discount: 0, duration: 30, included: "8 Soft Copies", shoot_type: "Maternity",
    still_valid: true, icon: "fa-person-pregnant"  },
  { name: "Maternity", outfit: "3 Outfit", description: "This session is designed for one person, with the option for partner or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
    amount: 90000.00, discount: 0, duration: 45, included: "12 Soft Copies", shoot_type: "Maternity",
    still_valid: true, icon: "fa-person-pregnant" },
  { name: "Maternity", outfit: "4 Outfit", description: "This session is designed for one person, with the option for partner or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
    amount: 120000.00, discount: 0, duration: 30, included: "15 Soft Copies", shoot_type: "Maternity",
    still_valid: true, icon: "fa-person-pregnant"  },
  { name: "Maternity", outfit: "5 Outfit", description: "This session is designed for one person, with the option for partner or siblings to join during one outfit change. Studio props are available, but you’ll need to bring any additional props.",
    amount: 150000.00, discount: 0, duration: 30, included: "18 Soft Copies", shoot_type: "Maternity",
    still_valid: true, icon: "fa-person-pregnant"  },

  { name: "Pre Wedding", outfit: "1 Outfit", description: "This session is designed for two people. Studio props are available, but you’ll need to bring any additional props.",
    amount: 32500.00, discount: 0, duration: 45, included: "5 Soft Copies", shoot_type: "Pre Wedding",
    still_valid: true, icon: "fa-people-pulling" },
  { name: "Pre Wedding", outfit: "2 Outfit", description: "This session is designed for two people. Studio props are available, but you’ll need to bring any additional props.",
    amount: 60000.00, discount: 0, duration: 30, included: "8 Soft Copies", shoot_type: "Pre Wedding",
    still_valid: true, icon: "fa-people-pulling"  },
  { name: "Pre Wedding", outfit: "3 Outfit", description: "This session is designed for two people. Studio props are available, but you’ll need to bring any additional props.",
    amount: 90000.00, discount: 0, duration: 45, included: "12 Soft Copies", shoot_type: "Pre Wedding",
    still_valid: true, icon: "fa-people-pulling" },
  { name: "Pre Wedding", outfit: "4 Outfit", description: "This session is designed for two people. Studio props are available, but you’ll need to bring any additional props.",
    amount: 120000.00, discount: 0, duration: 30, included: "15 Soft Copies", shoot_type: "Pre Wedding",
    still_valid: true, icon: "fa-people-pulling"  },
  { name: "Pre Wedding", outfit: "5 Outfit", description: "This session is designed for two people. Studio props are available, but you’ll need to bring any additional props.",
    amount: 150000.00, discount: 0, duration: 30, included: "18 Soft Copies", shoot_type: "Pre Wedding",
    still_valid: true, icon: "fa-people-pulling"  }

  # { name: "Passport Photos", outfit: "1 Outfit", description: "We would provide all appropriate props and backdrops for the shoots. Only the baby is allowed for this shoot. We also recommend bringing in any favorite toys along.",
  #   amount: 32500.00, discount: 0, duration: 45, included: "6 C0", shoot_type: "Passport Photos",
  #   still_valid: true, icon: "fa-solid fa-passport" },
  # { name: "Passport Photos", outfit: "2 Outfit", description: "We provide all appropriate props and backdrops for the shoots. We allow parent and sibling to join in one outfit change. We also recommend bringing in any favorite toys along.",
  #   amount: 50.00, discount: 0, duration: 30, included: "5 photos", shoot_type: "Passport Photos",
  #   still_valid: true, icon: "fa-solid fa-passport" }
])

puts "I am done creating....."

# Studio.create!([
#   {
#     name: "363 Photography Ajah",
#     location: "Ajah",
#     address: "KM 22 Lekki Epe Express way, Ilaje bus stop ajah",
#     phone: "08144985074",
#     email: "bambam363photos@gmail.com"
#   },
#   {
#     name: "363 Photography Surulere",
#     location: "Surulere",
#     address: "115A Bode Thomas Street, Surulere, Lagos",
#     phone: "07048891715",
#     email: "363photography1@gmail.com"
#   },
#   {
#     name: "363 Photography Ikeja",
#     location: "Ikeja",
#     address: "66 Adeniyi Jones, Ikeja, Lagos",
#     phone: "08090151168",
#     email: "363photography2@gmail.com"
#   }
# ])

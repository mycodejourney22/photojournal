# lib/tasks/create_customers_from_appointments.rake

namespace :customers do
  desc "Create customers from appointments that have associated sales"

  task create_from_appointments_with_sales: :environment do
    # Loop through all appointments that have at least one sale
    Customer.destroy_all
    Appointment.joins(:photo_shoot).distinct.find_each do |appointment|
      # Ensure each appointment only gets processed once for customer creation
      # next if appointment.customer_id.present?

      # Extract customer details from the appointment
      appointment_phone = appointment.questions.find { |q| q.question == 'Phone number' }
      if appointment_phone
        customer_name = appointment.name
        phone_number = normalize_phone_number(appointment_phone.answer)
        email = appointment.email

        # Find or create the customer
        customer = Customer.find_or_initialize_by(phone_number: phone_number)
        if customer.new_record?
          customer.name = customer_name
          customer.email = email
          customer.visits_count = 0
        else
          customer.increment_visits
        end
        customer.save



        # Output some information to the console for progress tracking
        puts "Customer #{customer.name} (#{customer.phone_number}) created/updated for appointment #{appointment.id}"
      end

      puts "Customer creation from appointments completed."
      end
  end
end

# Helper method for phone number normalization
def normalize_phone_number(phone_number)
  # Remove non-numeric characters
  phone_number = phone_number.gsub(/\D/, "")

  # Check if phone number starts with the country code +234 or 234
  if phone_number.start_with?("234")
    # Replace '234' with '0'
    phone_number = phone_number.sub("234", "0")
  elsif phone_number.start_with?("+234")
    # Remove the '+' and replace '234' with '0'
    phone_number = phone_number.sub("+234", "0")
  end

end

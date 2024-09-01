# lib/tasks/sales.rake
namespace :sales do
  desc "Update all sales with customer_id"
  task update_customer_ids: :environment do
    # Helper method to normalize phone numbers
    def normalize_phone_number(phone_number)
      cleaned_number = phone_number.gsub(/\D/, '') # Remove non-digit characters

      if cleaned_number.start_with?('234')
        '0' + cleaned_number[3..] # Replace '234' with '0'
      else
        cleaned_number
      end
    end

    Sale.find_each do |sale|
      if sale.customer_phone_number.nil? || sale.customer_phone_number == ""
        appointment = sale.appointment
        if appointment
          phone_number_question = appointment.questions.find { |q| q.question == 'Phone number' }
          next unless phone_number_question
          sale.customer_phone_number = normalize_phone_number(phone_number_question.answer)
          sale.save
        end
      end
    end

    Sale.find_each do |sale|

      # Find phone number in the appointment questions
      if sale.customer_phone_number
        phone_number = sale.customer_phone_number
        normalized_phone_number = normalize_phone_number(phone_number)
        customer = Customer.find_by(phone_number: normalized_phone_number)
        sale.update(customer_id: customer.id) if customer

        puts "Updated sale ##{sale.id} with customer_name ##{customer.name}" if customer
      end
    end

    puts "Sales update complete."
  end
end

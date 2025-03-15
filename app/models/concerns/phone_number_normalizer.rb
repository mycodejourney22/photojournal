# app/models/concerns/phone_number_normalizer.rb
module PhoneNumberNormalizer
  extend ActiveSupport::Concern

  def normalize_phone_number(phone_number)
    return nil unless phone_number

    # Remove non-numeric characters
    phone_number = phone_number.gsub(/\D/, "")

    # Check if phone number starts with the country code +234 or 234
    if phone_number.start_with?("234")
      # Replace '234' with '0'
      return phone_number.sub("234", "0")
    elsif phone_number.start_with?("+234")
      # Remove the '+' and replace '234' with '0'
      return phone_number.sub("+234", "0")
    end

    phone_number
  end
end

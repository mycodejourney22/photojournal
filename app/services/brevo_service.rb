require 'sib-api-v3-sdk'

class BrevoService
  def initialize
    SibApiV3Sdk.configure do |config|
      config.api_key['api-key'] = ENV['BREVO_API_KEY']
    end
    @contacts_api = SibApiV3Sdk::ContactsApi.new
  end

  def create_or_update_contact(customer)
    # Get the customer's purchases - group by product type
    product_types = customer.sales.where(void: false)
                            .pluck(:product_service_name)
                            .uniq
                            .join(", ")

    # Get last purchase date
    last_purchase = customer.sales.where(void: false)
                            .order(date: :desc)
                            .first&.date&.strftime("%Y-%m-%d")

    # Get preferred shoot type
    shoot_types = Appointment.joins(:questions)
                            .where(questions: { question: 'Type of shoots' })
                            .where("questions.answer IS NOT NULL")
                            .where(email: customer.email)
                            .pluck("questions.answer")
                            .group_by(&:itself)
                            .transform_values(&:count)
                            .max_by {|_, count| count}&.first

    # Get preferred location
    preferred_location = Appointment.where(email: customer.email)
                                   .group(:location)
                                   .order('count_id DESC')
                                   .count(:id)
                                   .first&.first

    # Map customer data to Brevo contact attributes
    contact = {
      email: customer.email,
      attributes: {
        FIRSTNAME: customer.name.split.first,
        LASTNAME: customer.name.split.drop(1).join(' '),
        PHONE: customer.phone_number,
        VISITS: customer.visits_count,
        TOTAL_SPENT: customer.sales.where(void: false).sum(:amount_paid).to_f,
        LAST_PURCHASE_DATE: last_purchase,
        PRODUCT_TYPES: product_types,
        PREFERRED_LOCATION: preferred_location,
        PREFERRED_SHOOT_TYPE: shoot_types,
        CREDITS: customer.credits.to_f,
        CUSTOMER_TYPE: customer.visits_count > 1 ? 'Returning' : 'New',
        FIRST_PURCHASE_DATE: customer.sales.where(void: false).order(date: :asc).first&.date&.strftime("%Y-%m-%d"),
        SOCIAL_MEDIA_CONSENT: get_social_media_consent(customer),
        REFERRAL_CODE: customer.referral_code
      },
      listIds: [ENV['BREVO_LIST_ID'].to_i],
      updateEnabled: true
    }

    begin
      @contacts_api.create_contact(contact)
      Rails.logger.info("Customer #{customer.name} (#{customer.email}) synced to Brevo")
      true
    rescue SibApiV3Sdk::ApiError => e
      Rails.logger.error("Brevo API error: #{e.message}")
      false
    end
  end


  def create_or_update_contacts(customers)
    results = { success: 0, failed: 0 }

    customers.each do |customer|
      if create_or_update_contact(customer)
        results[:success] += 1
      else
        results[:failed] += 1
      end
    end

    results
  end

  private

  def get_social_media_consent(customer)
    Appointment.joins(:questions)
              .where(email: customer.email)
              .where(questions: { question: 'Do you give us consent to share your pictures on our social media platform (Instagram, Threads, TikTok e.t.c) ?' })
              .order(created_at: :desc)
              .limit(1)
              .pluck("questions.answer")
              .first == 'Yes'
  end
end

# In lib/tasks/brevo_sync.rake
namespace :brevo do
  desc "Sync existing customers with Brevo, adding comprehensive customer data"
  task sync_customer_details: :environment do
    brevo_service = BrevoService.new

    # Optionally, log the progress
    total_customers = Customer.where.not(email: nil).count
    processed_count = 0
    errors_count = 0

    Customer.where.not(email: nil).find_each do |customer|
      begin
        # Get or generate referral code
        referral_code = customer.referral_code

        # Get product types
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

        # Prepare contact data
        contact = {
          email: customer.email,
          attributes: {
            FIRSTNAME: customer.name.split.first,
            LASTNAME: customer.name.split.drop(1).join(' '),
            REFERRAL_CODE: referral_code,
            PRODUCT_TYPES: product_types || 'No purchases',
            LAST_PURCHASE_DATE: last_purchase,
            PREFERRED_SHOOT_TYPE: shoot_types || 'Not specified',
            PREFERRED_LOCATION: preferred_location || 'Unknown',
            VISITS: customer.visits_count || 0,
            TOTAL_SPENT: customer.sales.where(void: false).sum(:amount_paid).to_f,
            CREDITS: customer.credits.to_f || 0,
            CUSTOMER_TYPE: customer.visits_count > 1 ? 'Returning' : 'New',
            FIRST_PURCHASE_DATE: customer.sales.where(void: false).order(date: :asc).first&.date&.strftime("%Y-%m-%d"),
            SOCIAL_MEDIA_CONSENT: get_social_media_consent(customer) || false
          },
          updateEnabled: true
        }

        # Update contact in Brevo
        contacts_api = SibApiV3Sdk::ContactsApi.new
        contacts_api.update_contact(contact[:email], contact)

        processed_count += 1
        print "." if processed_count % 10 == 0
      rescue => e
        errors_count += 1
        puts "\nError processing #{customer.email}: #{e.message}"
        puts e.backtrace.join("\n") if Rails.env.development?
      end
    end

    puts "\nProcessed #{processed_count} out of #{total_customers} customers"
    puts "Encountered #{errors_count} errors"
  end

  # Helper method to check social media consent
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

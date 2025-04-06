class BrevoSyncJob < ApplicationJob
  queue_as :default

  def perform(customer_id)
    customer = Customer.find(customer_id)
    return unless customer.email.present?

    brevo_service = BrevoService.new
    brevo_service.create_or_update_contact(customer)
  end


end

class BrevoSyncAllJob < ApplicationJob
  queue_as :default

  def perform
    # Sync in batches to avoid memory issues
    Customer.where.not(email: nil).find_in_batches(batch_size: 100) do |batch|
      brevo_service = BrevoService.new
      brevo_service.create_or_update_contacts(batch)
    end
  end
end

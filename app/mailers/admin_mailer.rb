class AdminMailer < ApplicationMailer
  default from: '363 Photography <noreply@363photography.org>'

  def new_refund_request(refund_request)
    @refund_request = refund_request
    @appointment = @refund_request.appointment

    # Find the appropriate admin email based on the location
    admin_email = find_admin_email_for_location(@appointment.location)

    mail(
      to: admin_email,
      subject: "New refund request from #{@appointment.name} - Request ##{@refund_request.id}"
    )
  end

  private

  def find_admin_email_for_location(location)
    # Default email if we can't determine location
    default_email = User.where(role: 'admin').first&.email || 'admin@363photography.org'

    # Try to match location to find the appropriate admin
    case location.downcase
    when /ikeja/
      User.where(role: ['admin', 'ikeja']).first&.email || default_email
    when /surulere/
      User.where(role: ['admin', 'surulere']).first&.email || default_email
    when /ajah/, /ilaje/
      User.where(role: ['admin', 'ajah']).first&.email || default_email
    else
      default_email
    end
  end
end

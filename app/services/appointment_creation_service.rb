# app/services/appointment_creation_service.rb
class AppointmentCreationService
  def initialize(params, current_user = nil, session = nil)
    @params = params
    @current_user = current_user
    @session = session || {}
  end

  def call
    appointment = Appointment.new(@params)
    appointment.set_defaults(@current_user)
    appointment.uuid = SecureRandom.uuid

    if @session.present? && @session[:referral_code].present?
      appointment.referral_source = @session[:referral_code]
    end

    if appointment.save
      schedule_notifications(appointment)
      process_referral(appointment) if appointment.referral_source.present?
      return { success: true, appointment: appointment }
    else
      return { success: false, appointment: appointment }
    end
  end

  private

  def schedule_notifications(appointment)
    appointment.schedule_policy_email
    appointment.schedule_reminder_email
    AppointmentNotificationJob.perform_later(appointment, 'created')
  end

  def process_referral(appointment)
    # Find the referral by code
    referral = Referral.find_by(code: appointment.referral_source)
    return unless referral && referral.pending?

    # Create or update the customer
    phone_number = extract_phone_number_from_appointment(appointment)
    customer = Customer.find_by(phone_number: phone_number)

    unless customer
      customer = Customer.new(
        name: appointment.name,
        email: appointment.email,
        phone_number: phone_number
      )
      customer.save
    end

    # Mark the referral as used by this customer
    referral.mark_as_used(customer)

    # Send welcome email to the referred customer
    ReferralMailer.welcome_referred_customer_email(referral).deliver_later
  end

  def extract_phone_number_from_appointment(appointment)
    appointment.questions.find { |q| q.question == 'Phone number' }&.answer
  end
end

# app/components/appointment_card_component.rb
class AppointmentCardComponent < ViewComponent::Base
  include AppointmentsHelper

  def initialize(appointment:)
    @appointment = appointment
  end

  def status_class
    if @appointment.no_show
      "status-no-show"
    elsif !@appointment.status
      "status-cancelled"
    else
      "status-active"
    end
  end

  private

  attr_reader :appointment
end

class AppointmentStatus
  def initialize(appointment)
    @appointment = appointment
  end

  def available_for_booking?
    !@appointment.no_show && @appointment.status
  end

  def past?
    @appointment.start_time < Time.zone.now
  end

  def upcoming?
    @appointment.start_time > Time.zone.now && available_for_booking?
  end

  def today?
    @appointment.start_time.to_date == Time.zone.today && available_for_booking?
  end
end

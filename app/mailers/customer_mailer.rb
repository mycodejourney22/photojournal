class CustomerMailer < ApplicationMailer

  default from: '363 Photography <noreply@363photography.org>'

  def refund_request_received(refund_request)
    @refund_request = refund_request
    @appointment = @refund_request.appointment

    mail(
      to: @appointment.email,
      subject: "Your refund request has been received - Request ##{@refund_request.id}"
    )
  end

  def refund_request_approved(refund_request)
    @refund_request = refund_request
    @appointment = @refund_request.appointment

    mail(
      to: @appointment.email,
      subject: "Your refund request has been approved - Request ##{@refund_request.id}"
    )
  end

  def refund_request_declined(refund_request)
    @refund_request = refund_request
    @appointment = @refund_request.appointment

    mail(
      to: @appointment.email,
      subject: "Update on your refund request - Request ##{@refund_request.id}"
    )
  end

  def refund_processed(refund_request)
    @refund_request = refund_request
    @appointment = @refund_request.appointment

    mail(
      to: @appointment.email,
      subject: "Your refund has been processed - Request ##{@refund_request.id}"
    )
  end
end

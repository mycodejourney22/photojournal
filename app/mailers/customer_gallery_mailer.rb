class CustomerGalleryMailer < ApplicationMailer
  default from: '363 Photography <noreply@363photography.org>'

  def verification_email(email, code)
    @code = code
    @expires_at = 30.minutes.from_now.strftime("%I:%M %p")

    mail(
      to: email,
      subject: "Your 363 Photography Gallery Access Code"
    )
  end
end

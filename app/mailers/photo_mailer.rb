class PhotoMailer < ApplicationMailer
  default from: '363 Photography'

  def send_gallery(appointment, gallery_url, gallery)
    @appointment = appointment
    @gallery_url =gallery_url
    @gallery = gallery

    mail(to: @appointment.email, subject: 'Your Photo Gallery from 363 Photography')
  end

  def thank_you_email(photoshoot)
    @photoshoot = photoshoot
    mail_from_studio(to: @photoshoot.appointment.email, subject: 'Thank you for trusting 363 Photography')
  end
end

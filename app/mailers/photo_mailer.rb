class PhotoMailer < ApplicationMailer
  default from: 'info@363photography.org'

  def send_gallery(appointment, gallery_url, gallery)
    @appointment = appointment
    @gallery_url =gallery_url
    @gallery = gallery

    mail(to: @appointment.email, subject: 'Your Photo Gallery from 363 Photography')
  end

end

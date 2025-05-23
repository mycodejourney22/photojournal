# app/mailers/gallery_mailer.rb
class GalleryMailer < ApplicationMailer
  default from: '363 Photography <noreply@363photography.org>'

  def upload_complete(gallery)
    @gallery = gallery
    @appointment = gallery.appointment
    @mapping = GalleryMapping.find_by(gallery_id: gallery.id)

    # Find staff to notify - ideally the editor or someone responsible for the gallery
    staff_email = find_staff_email(gallery)
    return if staff_email.blank?

    # mail_from_studio(
    #   to: staff_email,
    #   subject: "Gallery uploaded to Smugmug: #{gallery.title}"
    # )
  end

  def upload_failed(gallery, error_message)
    @gallery = gallery
    @appointment = gallery.appointment
    @error_message = error_message

    # Find staff to notify - ideally the editor or someone responsible for the gallery
    staff_email = find_staff_email(gallery)
    return if staff_email.blank?

    # mail_from_studio(
    #   to: staff_email,
    #   subject: "FAILED: Gallery upload to Smugmug: #{gallery.title}"
    # )
  end

  private

  def find_staff_email(gallery)
    # Try to find the most appropriate staff member to notify
    # if gallery.appointment&.photo_shoot&.editor&.email.present?
    #   gallery.appointment.photo_shoot.editor.email
    # elsif gallery.appointment&.photo_shoot&.photographer&.email.present?
    #   gallery.appointment.photo_shoot.photographer.email
    # else
      # Default to a system admin or manager
    User.where(role: ['admin', 'manager', 'super_admin']).first&.email
    # end
  end
end

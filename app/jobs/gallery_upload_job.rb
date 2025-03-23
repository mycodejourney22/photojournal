# app/jobs/gallery_upload_job.rb
class GalleryUploadJob < ApplicationJob
  queue_as :smugmug_uploads

  retry_on StandardError, attempts: 3, wait: 5.minutes

  def perform(gallery_id)
    gallery = Gallery.find_by(id: gallery_id)

    # Skip if gallery doesn't exist or has no photos
    unless gallery && gallery.photos.attached?
      Rails.logger.info("Gallery ##{gallery_id} doesn't exist or has no photos. Skipping upload.")
      return
    end

    # Find or create gallery mapping
    mapping = GalleryMapping.find_or_initialize_by(gallery_id: gallery_id)

    # Only proceed if not already completed
    if mapping.completed?
      Rails.logger.info("Gallery ##{gallery_id} already uploaded to Smugmug. Skipping.")
      return
    end

    # Update status to processing
    mapping.status = :processing
    mapping.save(validate: false) # Skip validation for now

    # Attach to customer if available from appointment
    if gallery.appointment && customer_for_appointment(gallery.appointment)
      customer =  customer_for_appointment(gallery.appointment)
      mapping.customer = customer
      mapping.save(validate: false) # Skip validation
    end

    begin
      # Prepare files for upload
      files = prepare_photos(gallery.photos)

      # Upload to Smugmug
      Rails.logger.info("Starting upload for Gallery ##{gallery_id} to Smugmug")
      result = SmugmugService.new.upload_gallery(gallery.appointment, files)

      if result[:success]
        # Update mapping with Smugmug details
        mapping.assign_attributes(
          smugmug_key: result[:gallery_key],
          smugmug_url: result[:gallery_url],
          status: :completed,
          error_message: nil,
          metadata: {
            successful_uploads: result[:results][:success].size,
            failed_uploads: result[:results][:failed].size,
            upload_details: result[:results]
          }
        )

        # Now save with validation
        if mapping.save
          Rails.logger.info("Successfully uploaded Gallery ##{gallery_id} to Smugmug")

          # Generate share token
          mapping.generate_share_token

          # Notify staff of successful upload if mailer exists
          GalleryMailer.upload_complete(gallery).deliver_later if defined?(GalleryMailer)
        else
          error_message = "Failed to save gallery mapping: #{mapping.errors.full_messages.join(', ')}"
          Rails.logger.error(error_message)

          # Mark as failed but ensure it saves
          mapping.status = :failed
          mapping.error_message = error_message
          mapping.save(validate: false)

          raise StandardError, error_message
        end
      else
        # Handle failure
        error_message = "Smugmug upload failed: #{result[:error]}"
        Rails.logger.error(error_message)

        mapping.status = :failed
        mapping.error_message = error_message
        mapping.save(validate: false)

        # Notify staff of failure if mailer exists
        GalleryMailer.upload_failed(gallery, error_message).deliver_later if defined?(GalleryMailer)

        raise StandardError, error_message
      end
    rescue StandardError => e
      # Handle unexpected errors
      error_message = "Error in GalleryUploadJob: #{e.class.name}: #{e.message}"
      Rails.logger.error(error_message)
      Rails.logger.error(e.backtrace.join("\n"))

      mapping.status = :failed
      mapping.error_message = error_message
      mapping.save(validate: false)

      # Notify staff of failure if mailer exists
      GalleryMailer.upload_failed(gallery, error_message).deliver_later if defined?(GalleryMailer)

      # Re-raise to trigger retry
      raise e
    end
  end

  private

  def prepare_photos(photos)
    photos.map do |photo|
      # Create a file-like object that SmugmugService can work with
      OpenStruct.new(
        original_filename: photo.filename.to_s,
        content_type: photo.content_type,
        read: -> { photo.download }
      )
    end
  end

  def customer_for_appointment(appointment)
    # Try to find customer by phone number
    phone_number = appointment.questions.find { |q| q.question == 'Phone number' }&.answer
    Customer.find_by(phone_number: phone_number) if phone_number.present?
  end
end

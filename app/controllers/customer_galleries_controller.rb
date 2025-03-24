class CustomerGalleriesController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'public'

  before_action :set_customer, only: [:index, :show]
  before_action :verify_authentication, only: [:index, :show]

  # Landing page for gallery access
  def access
    # Just render the form
  end

  # Handle the authentication request
  def authenticate
    # Find the customer by email or phone
    @customer = find_customer(params[:identifier])

    if @customer
      # Generate a verification code
      code = generate_verification_code

      # Store code in session with expiration
      session[:gallery_verification] = {
        code: code,
        customer_id: @customer.id,
        expires_at: 30.minutes.from_now.to_i
      }

      # Send verification code
      if params[:identifier].include?('@')
        send_email_verification(params[:identifier], code)
        redirect_to verify_customer_galleries_path, notice: "A verification code has been sent to your email."
      else
        send_sms_verification(params[:identifier], code)
        redirect_to verify_customer_galleries_path, notice: "A verification code has been sent to your phone."
      end
    else
      # No customer found with this email/phone
      flash.now[:alert] = "We couldn't find any galleries associated with this contact information."
      render :access
    end
  end

  # Verification code entry page
  def verify
    # Just render the verification form
    redirect_to access_customer_galleries_path unless session[:gallery_verification].present?
  end

  # Process the verification code
  def process_verification
    verification = session[:gallery_verification]

    # Check if verification session exists and hasn't expired
    if verification.present? &&
       verification['expires_at'] > Time.now.to_i &&
       verification['code'] == params[:code]

      # Mark as authenticated in the session
      session[:gallery_authenticated] = true
      session[:customer_id] = verification['customer_id']

      # Clear verification data
      session.delete(:gallery_verification)

      # Redirect to galleries list
      redirect_to customer_galleries_path
    else
      flash.now[:alert] = "Invalid or expired verification code. Please try again."
      render :verify
    end
  end

  # List all galleries for the customer
  def index
    @galleries = find_customer_galleries(@customer)
  end

  # Show a specific gallery
  def show
    @gallery = Gallery.find(params[:id])
    @gallery_mapping = GalleryMapping.find_by(gallery_id: @gallery.id)

    # Ensure the gallery belongs to the customer
    unless @gallery.appointment && (@gallery.appointment.email == @customer.email || gallery_belongs_to_customer?(@gallery, @customer))
      redirect_to customer_galleries_path, alert: "You don't have access to this gallery."
      return
    end

    # Determine which photo source to use (Smugmug or local)
    @use_smugmug = false

    # Try to use Smugmug photos if the gallery has been uploaded to Smugmug
    if @gallery_mapping&.completed? && @gallery_mapping&.smugmug_key.present?
      begin
        @smugmug_photos = SmugmugService.new.get_gallery_photos(@gallery_mapping.smugmug_key)
        if @smugmug_photos.present?
          @use_smugmug = true
          Rails.logger.info("Using Smugmug photos for gallery #{@gallery.id}")
        else
          Rails.logger.warn("No Smugmug photos found for gallery #{@gallery.id}")
        end
      rescue => e
        Rails.logger.error("Error fetching Smugmug photos: #{e.message}")
        # Fall back to local photos
      end
    end

    # Fall back to local photos if Smugmug photos aren't available
    unless @use_smugmug
      @photos = @gallery.photos
      Rails.logger.info("Using local photos for gallery #{@gallery.id}")
    end
  end

  # Logout from gallery access
  def logout
    session.delete(:gallery_authenticated)
    session.delete(:customer_id)
    redirect_to access_customer_galleries_path, notice: "You have been logged out."
  end

  private

  def set_customer
    @customer = Customer.find_by(id: session[:customer_id])
    redirect_to access_customer_galleries_path unless @customer
  end

  def verify_authentication
    redirect_to access_customer_galleries_path unless session[:gallery_authenticated] && session[:customer_id]
  end

  def find_customer(identifier)
    if identifier.include?('@')
      # Find by email
      Customer.find_by(email: identifier)
    else
      # Find by phone (normalize first)
      normalized_phone = normalize_phone_number(identifier)
      Customer.find_by(phone_number: normalized_phone)
    end
  end

  def normalize_phone_number(phone_number)
    # Remove non-numeric characters
    digits_only = phone_number.gsub(/\D/, '')

    # Check if phone number starts with the country code +234 or 234
    if digits_only.start_with?("234")
      # Replace '234' with '0'
      return digits_only.sub("234", "0")
    elsif digits_only.start_with?("+234")
      # Remove the '+' and replace '234' with '0'
      return digits_only.sub("+234", "0")
    end

    phone_number
  end

  def generate_verification_code
    # Generate a 6-digit code
    SecureRandom.random_number(100000..999999).to_s
  end

  def send_email_verification(email, code)
    # Send email with verification code
    CustomerGalleryMailer.verification_email(email, code).deliver_later
  end

  def send_sms_verification(phone, code)
    # Send SMS with verification code
    sms_service = SmsService.new
    message = "Your 363 Photography gallery access code is: #{code}. This code will expire in 30 minutes."
    sms_service.send_sms(phone, message)
  end

  def find_customer_galleries(customer)
    # Find all galleries associated with this customer via appointments
    # This includes direct associations and phone number matches

    # Start with appointments associated with customer email
    appointments = Appointment.where(email: customer.email)

    # Add appointments associated with customer phone number
    phone_appointments = Appointment.joins(:questions)
                                   .where(questions: { question: 'Phone number' })
                                   .where("questions.answer LIKE ?", "%#{customer.phone_number}%")

    appointments = (appointments + phone_appointments).uniq

    # Get all galleries for these appointments with their mappings to Smugmug
    galleries = Gallery.where(appointment_id: appointments.map(&:id))
                     .includes(:appointment, :gallery_mapping, :photos_attachments)
                     .order(created_at: :desc)

    # Filter out galleries that have neither local photos nor Smugmug photos
    # Keep galleries that have either local photos or Smugmug mapping
    galleries.select do |gallery|
      gallery.photos.attached? ||
      (gallery.gallery_mapping&.completed? && gallery.gallery_mapping&.smugmug_key.present?)
    end
  end

  def gallery_belongs_to_customer?(gallery, customer)
    # Check if gallery belongs to customer via phone number match
    phone_number = gallery.appointment.questions.find { |q| q.question == 'Phone number' }&.answer
    phone_number.present? && normalize_phone_number(phone_number) == customer.phone_number
  end
end

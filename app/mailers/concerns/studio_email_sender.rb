# app/mailers/concerns/studio_email_sender.rb
module StudioEmailSender
    extend ActiveSupport::Concern
    
    def studio_email_for(location)
      return "info@363photography.org" unless location.present?
      
      case location.to_s.downcase
      when "ikeja"
        Rails.application.credentials.dig(:studio_emails, :ikeja, :address) || "ikeja@363photography.org"
      when "surulere"
        Rails.application.credentials.dig(:studio_emails, :surulere, :address) || "surulere@363photography.org"
      when "ajah"
        Rails.application.credentials.dig(:studio_emails, :ajah, :address) || "ajah@363photography.org"
      else
        Rails.application.credentials.dig(:studio_emails, :info, :address) || "info@363photography.org"
      end
    end
    
    def studio_email_password(location)
      return Rails.application.credentials.gmail.password unless location.present?
      
      case location.to_s.downcase
      when "ikeja"
        Rails.application.credentials.dig(:studio_emails, :ikeja, :password) || Rails.application.credentials.gmail.password
      when "surulere"
        Rails.application.credentials.dig(:studio_emails, :surulere, :password) || Rails.application.credentials.gmail.password
      when "ajah"
        Rails.application.credentials.dig(:studio_emails, :ajah, :password) || Rails.application.credentials.gmail.password
      else
        Rails.application.credentials.dig(:studio_emails, :info, :password) || Rails.application.credentials.gmail.password
      end
    end
    
    def mail_from_studio(options = {}, location = nil)
      if location.present?
        from_email = studio_email_for(location)
        options[:from] ||= "363 Photography <#{from_email}>"
        
        mail(options).tap do |message|
          message.delivery_method.settings.merge!(
            user_name: from_email,
            password: studio_email_password(location)
          )
        end
      else
        mail(options)
    end
    end
end
class ApplicationMailer < ActionMailer::Base
  include StudioEmailSender
  default from: "from@example.com"
  layout "mailer"

  def studio_email_for(location)
    return "info@363photography.org" unless location.present?

    case location.to_s.downcase
    when "ikeja"
      "363photography2@gmail.com"
    when "surulere"
      "363photography1@gmail.com" 
    when "ajah"
      "bambam363photos@gmail.com"
    else
      "info@363photography.org"
    end
  end
end

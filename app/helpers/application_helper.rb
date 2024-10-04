module ApplicationHelper

  def format_large_number(number)
    if number >= 1_000_000
      "#{(number / 1_000_000.0).round(1)}M"
    elsif number >= 1_000
      "#{(number / 1_000.0).round(1)}K"
    else
      number.to_s
    end
  end


    def dynamic_appointments_url
      if request.path.include?("past")
        past_appointments_path
      elsif request.path.include?("upcoming")
        upcoming_appointments_path
      else
        appointments_path
      end
    end


end

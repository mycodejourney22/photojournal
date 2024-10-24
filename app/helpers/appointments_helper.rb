# In your helper file (e.g., app/helpers/appointments_helper.rb)
module AppointmentsHelper
  def find_question_answer(appointment, question_text)
    question = appointment.questions.find { |q| q.question == question_text }
    question&.answer || 'N/A' # Default to 'N/A' if not found
  end

  def format_date_string(date_str)
    date = DateTime.parse(date_str)
    date.strftime("%A, %d, %Y")
  end
end

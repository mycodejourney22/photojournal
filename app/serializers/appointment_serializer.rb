# app/serializers/appointment_serializer.rb
class AppointmentSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :email, :status, :payment_status, :formatted_start_time, :formatted_time, :location

  attribute :price do
    object.price ? PriceSerializer.new(object.price) : nil
  end

  attribute :questions do
    object.questions.map do |question|
      {
        question: question.question,
        answer: question.answer
      }
    end
  end

  attribute :payment_completed do
    object.payment_status
  end
end

# app/controllers/api/v1/appointments_controller.rb
module Api
  module V1
    class AppointmentsController < Api::BaseController
      def create
        service = AppointmentCreationService.new(appointment_params, nil,
                                                { referral_code: params[:referral_code] })
        result = service.call

        if result[:success]
          appointment = result[:appointment]

          render json: {
            success: true,
            appointment: {
              id: appointment.id,
              uuid: appointment.uuid,
              name: appointment.name,
              email: appointment.email,
              time: appointment.formatted_time,
              date: appointment.formatted_start_time,
              location: appointment.location,
              status: appointment.status,
              payment_required: appointment.price_id.present? && !appointment.payment_status
            }
          }, status: :created
        else
          render json: {
            success: false,
            errors: result[:appointment].errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def show
        @appointment = Appointment.find_by(uuid: params[:id])

        if @appointment
          render json: {
            id: @appointment.id,
            uuid: @appointment.uuid,
            name: @appointment.name,
            email: @appointment.email,
            time: @appointment.formatted_time,
            date: @appointment.formatted_start_time,
            location: @appointment.location,
            status: @appointment.status,
            payment_status: @appointment.payment_status,
            price_id: @appointment.price_id,
            price_amount: @appointment.price&.amount
          }
        else
          render json: { error: 'Appointment not found' }, status: :not_found
        end
      end

      def cancel
        appointment = Appointment.find_by(uuid: params[:id])

        if appointment && appointment.update(status: false)
          AppointmentNotificationJob.perform_later(appointment, 'canceled')
          render json: { success: true, message: 'Appointment cancelled successfully' }
        else
          render json: { success: false, message: 'Failed to cancel appointment' }, status: :bad_request
        end
      end

      private

      def appointment_params
        params.require(:appointment).permit(
          :name,
          :email,
          :location,
          :start_time,
          :price_id,
          questions_attributes: [:question, :answer]
        )
      end
    end
  end
end

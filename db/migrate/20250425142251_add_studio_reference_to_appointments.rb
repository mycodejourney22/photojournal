class AddStudioReferenceToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_reference :appointments, :studio, foreign_key: true, null: true
  end
end

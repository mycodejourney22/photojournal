class Expense < ApplicationRecord
  validates :date, :description, :category, :staff, :amount, :location, presence: true


  def staff_name
    # Check if `staff` is already an associated Staff object or a name string
    staff_id = self.staff.to_i
    if staff_id.zero?  # Treats `staff` as a name if it's not an ID
      self.staff
    else  # `staff` is an ID, so find the associated Staff name
      Staff.find_by(id: staff_id)&.name || "Unknown Staff"
    end
  end
end

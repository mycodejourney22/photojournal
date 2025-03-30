// app/javascript/controllers/datepicker_controller.js
import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"


export default class extends Controller {
  connect() {
    console.log("Flatpickr controller connected");

    // Simple initialization with fixed config
    this.flatpickr = flatpickr(this.element, {
      enableTime: true,
      dateFormat: "Y-m-d H:i",
      altFormat: "F j, Y at h:i K",
      altInput: true,
      allowInput: true,
      defaultHour: 12, // Set default to noon instead of midnight
      minDate: "today"
    });
  }

  disconnect() {
    if (this.flatpickr) {
      this.flatpickr.destroy();
    }
  }
}

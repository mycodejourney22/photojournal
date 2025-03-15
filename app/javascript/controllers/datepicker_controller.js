// app/javascript/controllers/datepicker_controller.js
import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  connect() {
    // Configure flatpickr to disable time selection
    flatpickr(this.element, {
      enableTime: false,
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "F j, Y",
      allowInput: true
    });
  }
}

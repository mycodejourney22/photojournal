// app/javascript/controllers/calendar_controller.js
import { Controller } from "@hotwired/stimulus";
import { Calendar } from "@fullcalendar/core";
import dayGridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction"; // For day click interaction

export default class extends Controller {
  static targets = ["timeSlots", "calendar"];


  connect() {
    this.initializeCalendar();
    this.previousButton = null;
    this.highlightOnPageLoad();
  }



  initializeCalendar() {
    const calendarEl = this.calendarTarget;
    const calendar = new Calendar(calendarEl, {
      timeZone: 'Africa/Lagos',
      plugins: [dayGridPlugin, interactionPlugin],
      initialView: 'dayGridMonth',
      validRange: {
        start: new Date()
      },
      selectable: true,
      dateClick: (info) => { // Use an arrow function to maintain `this` context
        const selectedDate = info.dateStr;
        document.getElementById('selected_date_input').value = selectedDate;
        this.highlightSelectedDate(info.dateStr);
        this.handleDateClick(info); // Call the first handler
        this.dateSelected(info); // Call the second handler
      },
    });
    calendar.render();
  }

  handleDateClick(info) {
    const selectedDate = info.dateStr;
    console.log(selectedDate)
    // Fetch available slots for this date (replace with your own backend API endpoint)
    fetch(`/appointments/available_hours?date=${selectedDate}`)
      .then(response => response.json())
      .then(data => this.displayAvailableSlots(data, selectedDate))
      .catch(error => console.error('Error fetching slots:', error));
  }

  highlightSelectedDate(dateStr){
    document.querySelectorAll('.fc-day').forEach(function(dayEl) {
      dayEl.firstElementChild.style.backgroundColor = '';
      dayEl.style.fontWeight = 'normal';/// Reset color for all dates
    });

    const selectedDay = document.querySelector(`.fc-day[data-date="${dateStr}"]`);
    if (selectedDay) {
      selectedDay.firstElementChild.style.backgroundColor = '#eecc24'; // Custom color
      selectedDay.style.fontWeight = 'bold';
    }

  }

  highlightOnPageLoad(){
    const storedDate = document.getElementById('selected_date_input').value;
    if (storedDate) {
      this.highlightSelectedDate(storedDate);
    }

  }

  displayAvailableSlots(slots, date) {
    this.timeSlotsTarget.innerHTML = `<h3> ${this._formatDate(date)}</h3>`;
    slots.forEach(slot => {
      const slotElement = document.createElement('button');
      slotElement.textContent = slot;
      slotElement.dataset.action = "click->calendar#selectTime";
      slotElement.dataset.slot = slot; // Store the slot value in the button's data attribute
      this.timeSlotsTarget.appendChild(slotElement);
    });
    // this.calendarTarget.classList.add('hidden')
  }


  selectTime(event) {
    event.preventDefault();
    const selectedTime = event.target.dataset.slot;
    this.selectedTime = selectedTime;
    const nextButton = event.target.nextElementSibling;
    const parentElement = event.target.parentElement;

    // Reset the width of the previously selected button
    if (this.previousTarget && this.previousTarget !== event.target) {
        this.previousTarget.style.width = '16rem';
    }

    if (this.previousButton && this.previousButton !== nextButton) {
        this.previousButton.classList.add('hidden');
        this.previousButton.classList.remove('btn-yellow');
        this.previousButton.parentElement.classList.remove('d-flex');
    }

    nextButton.classList.remove('hidden');
    nextButton.classList.add('btn-yellow');
    parentElement.classList.add('available_button');
    nextButton.classList.add('available_hours_width');
    event.target.style.width = '30%'; // Set new width

    // Update previousTarget and previousButton to current selections
    this.previousTarget = event.target;
    this.previousButton = nextButton;

    return new URLSearchParams(window.location.search);
}


  nextTime() {
    // Ensure that the selected time is available before proceeding
    if (this.selectedTime) {

      // For example, you can now combine the selected time with a date or other values
      const urlParams = new URLSearchParams(window.location.search);
      const selectedDate = urlParams.get('date');
      const selectedLocation = urlParams.get('location');
      const priceId = urlParams.get('price_id');


      // Combine the selected date and time into a single string, if needed
      const combinedDateTime = `${selectedDate.split('T')[0]}T${this.selectedTime}:00`;

      // Set the combined datetime value in a hidden input field
      document.getElementById('start_time_input').value = combinedDateTime;

      // Optionally, redirect to a new URL with the selected time and other parameters
      window.location.href = `new_customer?date=${combinedDateTime}&location=${selectedLocation}&price_id=${priceId}`;
    } else {
      console.log("No time selected yet.");
    }
  }


  dateSelected(event) {
    const selectedDate = new Date(event.date);
    const year = selectedDate.getFullYear();
    const month = String(selectedDate.getMonth() + 1).padStart(2, '0'); // Months are 0-based
    const day = String(selectedDate.getDate()).padStart(2, '0');
    const formattedDate = `${year}-${month}-${day}T00:00:00.000Z`;
    // Redirect to the available hours page with the selected date as a parameter
    document.getElementById('selected_date_input').value = formattedDate;

    // window.location.href = `available_hours?date=${formattedDate}`;
  }

  redirectToAvailableHours() {
    const selectedDate = document.getElementById('selected_date_input').value;
    const selectedLocation = document.querySelector('select[name="appointment[location]"]').value;
    const priceId = document.getElementById('appointment_price_id').value || null;

    // Check if we're editing an existing appointment
    const appointmentIdField = document.getElementById('appointment_id');
    const appointmentId = appointmentIdField ? appointmentIdField.value : null;

    console.log('Selected Date:', selectedDate);
    console.log('Selected Location:', selectedLocation);
    console.log('Price ID:', priceId);
    console.log('Appointment ID:', appointmentId);

    if (selectedDate && selectedLocation) {
      let url = `available_hours?date=${selectedDate}&location=${selectedLocation}`;

      if (priceId && priceId !== 'null') {
        url += `&price_id=${priceId}`;
      }

      // Include appointment ID if we're editing
      if (appointmentId) {
        url += `&id=${appointmentId}`;
      }

      console.log('Redirecting to:', url);
      window.location.href = url;
    } else {
      console.log('Missing required fields for redirection');
    }
  }



  _formatDate(newdate){
    let date = new Date(newdate);
    let options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    let formattedDate = date.toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      timeZone: 'Africa/Lagos'
    });
    return formattedDate
  }

}

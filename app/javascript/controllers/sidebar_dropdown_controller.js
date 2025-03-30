// app/javascript/controllers/sidebar_dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "menu"]

  connect() {
    // Check if the dropdown should be open on page load (if any child is active)
    const hasActiveChild = this.menuTarget.querySelector('.g-sidebar__dropdown-item--active');
    if (hasActiveChild) {
      this.open();
    }
  }

  toggle(event) {
    event.preventDefault();

    if (this.isOpen()) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.toggleTarget.classList.add('open');
    this.menuTarget.classList.add('open');
  }

  close() {
    this.toggleTarget.classList.remove('open');
    this.menuTarget.classList.remove('open');
  }

  isOpen() {
    return this.toggleTarget.classList.contains('open');
  }
}

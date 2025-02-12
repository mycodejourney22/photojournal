import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]

  toggle(event) {
    event.preventDefault()
    this.cardTarget.classList.toggle('hidden')
  }

  // Optional: Close when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.cardTarget.classList.add('hidden')
    }
  }

  connect() {
    document.addEventListener('click', this.clickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.clickOutside.bind(this))
  }
}

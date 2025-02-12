import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]

  toggle(event) {
    event.preventDefault()
    this.sidebarTarget.classList.toggle('active')
    console.log('Toggled sidebar')

    document.body.classList.toggle('overflow-hidden')
  }

  clickOutside(event) {
    if (this.sidebarTarget.classList.contains('active') &&
        !this.sidebarTarget.contains(event.target) &&
        !event.target.closest('.hamburger-btn')) {
      this.sidebarTarget.classList.remove('active')
      document.body.classList.remove('overflow-hidden')
    }
  }

  connect() {
    document.addEventListener('click', this.clickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.clickOutside.bind(this))
  }
}

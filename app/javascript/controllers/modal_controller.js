import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  open(event) {
    event.preventDefault()
    this.modalTarget.style.display = 'block'
    document.body.classList.add('modal-open')
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.style.display = 'none'
    document.body.classList.remove('modal-open')
  }

  closeBackground(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}

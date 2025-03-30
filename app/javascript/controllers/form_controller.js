// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {
  static targets = ["dateTimeField"]

  connect() {
    this.initializeFormElements()
  }

  initializeFormElements() {
    // Initialize any form-specific enhancements here
    this.initializeHelpText()
    this.enhanceRequiredFields()
    this.setupConfirmationChecks()
  }

  initializeHelpText() {
    // Add help text toggle functionality
    const helpIcons = this.element.querySelectorAll('.help-icon')

    helpIcons.forEach(icon => {
      icon.addEventListener('click', (e) => {
        const helpText = e.target.nextElementSibling
        if (helpText) {
          helpText.classList.toggle('visible')
        }
      })
    })
  }

  enhanceRequiredFields() {
    // Add visual indicators for required fields
    const requiredInputs = this.element.querySelectorAll('input[required], select[required], textarea[required]')

    requiredInputs.forEach(input => {
      const label = input.previousElementSibling
      if (label && label.tagName === 'LABEL') {
        if (!label.querySelector('.required-indicator')) {
          const indicator = document.createElement('span')
          indicator.classList.add('required-indicator')
          indicator.textContent = '*'
          label.appendChild(indicator)
        }
      }
    })
  }

  setupConfirmationChecks() {
    // Check password confirmation matches if present
    const passwordField = this.element.querySelector('input[type="password"]:not([id*="confirmation"])')
    const confirmationField = this.element.querySelector('input[id*="confirmation"][type="password"]')

    if (passwordField && confirmationField) {
      confirmationField.addEventListener('input', () => {
        if (passwordField.value !== confirmationField.value) {
          confirmationField.setCustomValidity('Passwords must match')
        } else {
          confirmationField.setCustomValidity('')
        }
      })
    }
  }

  // Date/time field initialization is now handled by the flatpickr controller
}

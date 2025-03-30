// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "feedback"]

  connect() {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.style.display = "none"
    }
  }

  copy() {
    // Get the text to copy
    const textToCopy = this.sourceTarget.value

    // Use the Clipboard API to copy text
    navigator.clipboard.writeText(textToCopy).then(
      () => {
        // Show success feedback if we have a feedback target
        if (this.hasFeedbackTarget) {
          this.feedbackTarget.style.display = "inline-block"

          // Hide the feedback after 2 seconds
          setTimeout(() => {
            this.feedbackTarget.style.display = "none"
          }, 2000)
        }
      },
      () => {
        // Fallback to traditional method if clipboard API fails
        this.legacyCopy(textToCopy)
      }
    )
  }

  legacyCopy(text) {
    // Create a temporary textarea
    const textarea = document.createElement('textarea')
    textarea.value = text
    textarea.style.position = 'fixed'  // Prevent scrolling to bottom
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)

    // Select and copy
    textarea.select()
    try {
      document.execCommand('copy')

      // Show feedback
      if (this.hasFeedbackTarget) {
        this.feedbackTarget.style.display = "inline-block"

        setTimeout(() => {
          this.feedbackTarget.style.display = "none"
        }, 2000)
      }
    } catch (err) {
      console.error('Failed to copy text: ', err)
    }

    // Clean up
    document.body.removeChild(textarea)
  }
}

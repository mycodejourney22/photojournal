import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="active-link"
export default class extends Controller {
  static targets = [ "link"]
  connect() {
    const currentPath = window.location.pathname
    this.linkTargets.forEach(link => {
      if (currentPath.startsWith(link.getAttribute('href'))){
        link.classList.add('active')
      }
    })

  }

}

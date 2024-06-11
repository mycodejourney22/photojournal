import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="active-link"
export default class extends Controller {
  static targets = [ "link" ]
  connect() {
    const currentPath = window.location.pathname
    console.log(`Current link is ${currentPath}` )
    this.linkTargets.forEach(link => {
      if (link.getAttribute('href') === currentPath) {
        link.classList.add('active')
      }
    })

  }

}

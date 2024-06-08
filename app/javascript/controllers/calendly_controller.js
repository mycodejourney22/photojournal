import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="calendly"
export default class extends Controller {
  static targets = ["table", "completed", "upcoming", "upfront"]
  connect() {

  }

  navigate(e){
    e.preventDefault()
   const url = this.completedTarget.getAttribute('data-url')
   fetch(url, {headers: {"Accept": "text/plain"}})
    .then(res => res.text())
    .then(data =>
      this.tableTarget.outerHTML = data)
  }

  upcomingnavigate(e){
    e.preventDefault()
    const url = this.upcomingTarget.getAttribute('data-url')
    fetch(url, {headers: {"Accept": "text/plain"}})
     .then(res => res.text())
     .then(data =>
       this.tableTarget.outerHTML = data)
  }

  upfrontnavigate(e){
    e.preventDefault()
    const url = this.upfrontTarget.getAttribute('data-url')
    fetch(url, {headers: {"Accept": "text/plain"}})
     .then(res => res.text())
     .then(data =>
       this.tableTarget.outerHTML = data)
  }

}

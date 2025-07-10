import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nav"
export default class extends Controller {
  static targets = ["past", "today", "upcoming", "inprogress", "link"]
  connect() {
    const currentPath = window.location.pathname
    this.linkTargets.forEach(link => {
      if (currentPath.endsWith(link.getAttribute('href'))){
        link.classList.add('active-nav')
      }
    })
  }


  switch(event){
    this.todayTarget.classList.remove("active")
    this.pastTarget.classList.remove("active")
    // this.notesTarget.classList.remove("active")
    this.upcomingTarget.classList.remove("active")
    if (this.hasInprogressTarget) {
      this.inprogressTarget.classList.remove("active")
    }
    event.currentTarget.classList.add("active")
  }

}

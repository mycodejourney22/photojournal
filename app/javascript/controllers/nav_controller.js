import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nav"
export default class extends Controller {
  static targets = ["completed", "upfront", "notes", "upcoming"]
  connect() {
  }


  switch(event){
    this.completedTarget.classList.remove("active")
    this.upfrontTarget.classList.remove("active")
    this.notesTarget.classList.remove("active")
    this.upcomingTarget.classList.remove("active")
    event.currentTarget.classList.add("active")
  }

}

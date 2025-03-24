// app/javascript/controllers/gallery_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lightbox", "slide", "counter"]

  connect() {
    // Initialize current slide index
    this.currentIndex = 0

    // Add keydown event listener for keyboard navigation
    document.addEventListener('keydown', this.handleKeydown.bind(this))
  }

  disconnect() {
    // Remove keydown event listener when controller disconnects
    document.removeEventListener('keydown', this.handleKeydown.bind(this))
  }

  openLightbox(event) {
    // Get the index from the clicked element
    const index = event.currentTarget.dataset.index || 0
    this.showSlide(parseInt(index, 10))

    // Show lightbox
    this.lightboxTarget.classList.add('active')
    document.body.style.overflow = 'hidden'
  }

  closeLightbox() {
    this.lightboxTarget.classList.remove('active')
    document.body.style.overflow = ''
  }

  nextSlide() {
    this.showSlide(this.currentIndex + 1)
  }

  prevSlide() {
    this.showSlide(this.currentIndex - 1)
  }

  showSlide(index) {
    // Handle index bounds
    const totalSlides = this.slideTargets.length

    if (index < 0) {
      index = totalSlides - 1
    } else if (index >= totalSlides) {
      index = 0
    }

    // Hide all slides
    this.slideTargets.forEach(slide => {
      slide.classList.remove('active')
    })

    // Show the selected slide
    this.slideTargets[index].classList.add('active')
    this.currentIndex = index

    // Update counter if it exists
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${index + 1} of ${totalSlides}`
    }
  }

  handleKeydown(event) {
    // Only handle keys when lightbox is active
    if (!this.lightboxTarget.classList.contains('active')) return

    switch (event.key) {
      case 'Escape':
        this.closeLightbox()
        break
      case 'ArrowRight':
        this.nextSlide()
        break
      case 'ArrowLeft':
        this.prevSlide()
        break
    }
  }

  // Handle click outside content to close
  backgroundClick(event) {
    if (event.target === this.lightboxTarget) {
      this.closeLightbox()
    }
  }
}

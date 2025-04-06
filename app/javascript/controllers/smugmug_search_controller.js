// app/javascript/controllers/smugmug_search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]

  connect() {
    console.log("Smugmug search controller connected");
    this.setupSearchListeners();
  }

  setupSearchListeners() {
    // Add event listeners for search button and input field
    const searchButton = document.getElementById('smugmug-search-button');
    const searchInput = document.getElementById('smugmug-search-input');
    const resultsContainer = document.getElementById('smugmug-search-results');

    if (searchButton && searchInput) {
      searchButton.addEventListener('click', () => this.performSearch(searchInput.value, resultsContainer));

      // Also search on Enter key
      searchInput.addEventListener('keydown', (event) => {
        if (event.key === 'Enter') {
          event.preventDefault();
          this.performSearch(searchInput.value, resultsContainer);
        }
      });
    }

    // Add delegation for the select gallery buttons
    document.addEventListener('click', (event) => {
      if (event.target.classList.contains('select-gallery-btn')) {
        this.selectGallery(event);
      }
    });
  }

  performSearch(query, resultsContainer) {
    if (!query || query.trim() === '') {
      if (resultsContainer) {
        resultsContainer.innerHTML = '<div class="g-content__empty"><p>Please enter a search term</p></div>';
      }
      return;
    }

    // Show loading indicator
    if (resultsContainer) {
      resultsContainer.innerHTML = '<div class="g-loading">Searching Smugmug galleries...</div>';
    }

    // Make the search request
    fetch(`/smugmug_admin/search_smugmug?query=${encodeURIComponent(query)}`, {
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      if (resultsContainer) {
        resultsContainer.innerHTML = html;
      }
    })
    .catch(error => {
      console.error('Error searching Smugmug galleries:', error);
      if (resultsContainer) {
        resultsContainer.innerHTML = `<div class="g-alert g-alert--error">Error searching galleries: ${error.message}</div>`;
      }
    });
  }

  selectGallery(event) {
    // Get the gallery details from the data attributes
    const galleryItem = event.target.closest('.g-result-item');
    if (!galleryItem) return;

    const galleryKey = galleryItem.dataset.galleryKey;
    const galleryUrl = galleryItem.dataset.galleryUrl;

    // Fill in the form fields with the selected gallery data
    const keyField = document.querySelector('input[name="smugmug_key"]');
    const urlField = document.querySelector('input[name="smugmug_url"]');

    if (keyField) keyField.value = galleryKey;
    if (urlField) urlField.value = galleryUrl;

    // Scroll to the form
    document.querySelector('.g-form-card').scrollIntoView({ behavior: 'smooth' });
  }
}

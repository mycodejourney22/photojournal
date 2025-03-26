// app/javascript/controllers/dropzone_controller.js
import { Controller } from "@hotwired/stimulus";
import Dropzone from "dropzone";
import { DirectUpload } from "@rails/activestorage";

// Connects to data-controller="dropzone"
export default class extends Controller {
  static targets = ["input"];

  connect() {
    this.dropZone = this.createDropZone();
    this.hideFileInput();
    this.bindEvents();
    Dropzone.autoDiscover = false; // necessary quirk for Dropzone error in console
  }

  createDropZone() {
    // Get options from data attributes with more generous defaults
    const maxFileSize = parseInt(this.data.get("maxFileSize") || 100); // 100MB
    const maxFiles = parseInt(this.data.get("maxFiles") || 50);
    const acceptedFiles = this.data.get("acceptedFiles") || "image/*";

    // Create new Dropzone instance with custom preview template
    return new Dropzone(this.element, {
      url: this.url,
      headers: this.headers,
      maxFiles: maxFiles,
      maxFilesize: maxFileSize, // In MB
      acceptedFiles: acceptedFiles,
      addRemoveLinks: true,
      autoQueue: false,
      timeout: 300000, // 5 minutes for large files
      createImageThumbnails: false, // Disable thumbnails to save resources
      // Custom compact preview template
      previewTemplate: `
        <div class="upload-item">
          <div class="upload-filename" data-dz-name></div>
          <div class="upload-size" data-dz-size></div>
          <div class="upload-progress-container">
            <div class="upload-progress">
              <div class="upload-progress-bar" data-dz-uploadprogress></div>
            </div>
            <div class="upload-percentage" data-dz-uploadprogress-text>0%</div>
          </div>
          <div class="upload-status">
            <span class="upload-success-icon">✓</span>
            <span class="upload-error-icon">✕</span>
            <span class="upload-error-message" data-dz-errormessage></span>
          </div>
          <div class="upload-actions">
            <a class="upload-remove" href="#" data-dz-remove>Remove</a>
            <a class="upload-cancel" href="#">Cancel</a>
          </div>
        </div>
      `
    });
  }

  hideFileInput() {
    this.inputTarget.style.display = "none";
    this.inputTarget.disabled = true;
  }

  bindEvents() {
    this.dropZone.on("addedfile", (file) => {
      setTimeout(() => {
        if (file.accepted) {
          this.createDirectUploadController(file).start();
        }
      }, 500);

      // Add percentage text to progress bar
      const progressElement = file.previewElement.querySelector('.upload-percentage');
      if (progressElement) {
        progressElement.textContent = '0%';
      }

      // Add cancel button functionality
      const cancelBtn = file.previewElement.querySelector('.upload-cancel');
      if (cancelBtn) {
        cancelBtn.addEventListener('click', (e) => {
          e.preventDefault();
          if (file.status === Dropzone.UPLOADING && file.controller && file.controller.xhr) {
            file.controller.xhr.abort();
          }
          this.dropZone.removeFile(file);
        });
      }
    });

    this.dropZone.on("removedfile", (file) => {
      if (file.controller) {
        this.removeElement(file.controller.hiddenInput);
      }
    });

    this.dropZone.on("canceled", (file) => {
      if (file.controller) {
        file.controller.xhr.abort();
      }
    });

    this.dropZone.on("processing", (file) => {
      if (this.submitButton) {
        this.submitButton.disabled = true;
      }
    });

    this.dropZone.on("queuecomplete", () => {
      if (this.submitButton) {
        this.submitButton.disabled = false;
      }
    });

    // Show upload size limit errors more clearly
    this.dropZone.on("error", (file, errorMessage) => {
      if (errorMessage.includes("File is too large")) {
        // Make size error more visible to user
        const errorElement = file.previewElement.querySelector('.upload-error-message');
        if (errorElement) {
          errorElement.textContent = `File too large! Maximum size is ${this.maxFileSize} MB`;
          errorElement.style.display = 'block';
        }
      }

      // Make the file row show error state
      file.previewElement.classList.add('upload-error');
    });

    // When upload is successful
    this.dropZone.on("success", (file) => {
      file.previewElement.classList.add('upload-success');
    });
  }

  get headers() {
    return { "X-CSRF-Token": this.getMetaValue("csrf-token") };
  }

  get url() {
    return this.inputTarget.getAttribute("data-direct-upload-url");
  }

  get maxFiles() {
    return this.data.get("maxFiles") || 50;
  }

  get maxFileSize() {
    return this.data.get("maxFileSize") || 100;
  }

  get acceptedFiles() {
    return this.data.get("acceptedFiles");
  }

  get addRemoveLinks() {
    return this.data.get("addRemoveLinks") || true;
  }

  get uploadMultiple() {
    return this.data.get("uploadMultiple") || false;
  }

  get form() {
    return this.element.closest("form");
  }

  get submitButton() {
    return this.findElement(this.form, "input[type=submit], button[type=submit]");
  }

  // Utility methods
  createDirectUploadController(file) {
    return new DirectUploadController(this, file);
  }

  getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`);
    return element ? element.getAttribute("content") : null;
  }

  findElement(root, selector) {
    if (typeof root === "string") {
      selector = root;
      root = document;
    }
    return root.querySelector(selector);
  }

  removeElement(el) {
    if (el && el.parentNode) {
      el.parentNode.removeChild(el);
    }
  }

  insertAfter(el, referenceNode) {
    return referenceNode.parentNode.insertBefore(el, referenceNode.nextSibling);
  }
}

class DirectUploadController {
  constructor(source, file) {
    this.directUpload = this.createDirectUpload(file, source.url, this);
    this.source = source;
    this.file = file;
  }

  start() {
    this.file.controller = this;
    this.hiddenInput = this.createHiddenInput();
    this.directUpload.create((error, attributes) => {
      if (error) {
        this.removeHiddenInput();
        this.emitDropzoneError(error);
      } else {
        this.hiddenInput.value = attributes.signed_id;
        this.emitDropzoneSuccess();
      }
    });
  }

  createHiddenInput() {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = this.source.inputTarget.name;
    this.source.insertAfter(input, this.source.inputTarget);
    return input;
  }

  removeHiddenInput() {
    if (this.hiddenInput && this.hiddenInput.parentNode) {
      this.hiddenInput.parentNode.removeChild(this.hiddenInput);
    }
  }

  directUploadWillStoreFileWithXHR(xhr) {
    this.bindProgressEvent(xhr);
    this.emitDropzoneUploading();
  }

  bindProgressEvent(xhr) {
    this.xhr = xhr;
    this.xhr.upload.addEventListener("progress", (event) =>
      this.uploadRequestDidProgress(event)
    );
  }

  uploadRequestDidProgress(event) {
    const progress = (event.loaded / event.total) * 100;

    // Update progress bar
    const progressElement = this.source.findElement(
      this.file.previewElement,
      ".upload-progress-bar"
    );
    if (progressElement) {
      progressElement.style.width = `${progress}%`;
    }

    // Update percentage text
    const progressTextElement = this.source.findElement(
      this.file.previewElement,
      ".upload-percentage"
    );
    if (progressTextElement) {
      progressTextElement.textContent = `${Math.round(progress)}%`;
    }
  }

  emitDropzoneUploading() {
    this.file.status = Dropzone.UPLOADING;
    this.source.dropZone.emit("processing", this.file);
  }

  emitDropzoneError(error) {
    this.file.status = Dropzone.ERROR;
    this.source.dropZone.emit("error", this.file, error);
    this.source.dropZone.emit("complete", this.file);
  }

  emitDropzoneSuccess() {
    this.file.status = Dropzone.SUCCESS;
    this.source.dropZone.emit("success", this.file);
    this.source.dropZone.emit("complete", this.file);
  }

  createDirectUpload(file, url, controller) {
    return new DirectUpload(file, url, controller);
  }
}

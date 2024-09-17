# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true
# pin "flatpickr" # @4.6.13
pin "flatpickr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/flatpickr.js"
pin "@rails/ujs", to: "@rails--ujs.js" # @7.1.3
pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@3.7.0/dist/chart.esm.js"
pin "dropzone" # @6.0.0
pin "just-extend" # @5.1.1
pin "@rails/activestorage", to: "@rails--activestorage.js" # @7.2.100
pin "dropzone_controller", to: "controllers/dropzone_controller.js"
pin "dropzone_helpers", to: "helpers/dropzone.js"

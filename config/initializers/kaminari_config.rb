# frozen_string_literal: true

Kaminari.configure do |config|
  config.default_per_page = 10  # You can change this to your preferred items per page
  config.window = 2             # Number of pages to show around the current page
  config.outer_window = 1        # Number of pages to show at the beginning and end
  config.left = 0               # Left-side pages, you can set to 0 to exclude
  config.right = 0               # Right-side pages, you can set to 0 to exclude
  config.page_method_name = :page
  config.param_name = :page
end

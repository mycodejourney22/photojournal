# lib/tasks/reset_data.rake
namespace :db do
  desc "Destroy all records in specific order: GalleryMapping, Gallery, Sales, Appointment, Customer"
  task reset_data: :environment do
    # Set up counters to track progress
    counts = {}

    puts "Starting data reset process..."

    # 1. Destroy all GalleryMappings
    puts "Destroying GalleryMappings..."
    counts[:gallery_mappings] = GalleryMapping.count
    GalleryMapping.destroy_all
    puts "✓ Destroyed #{counts[:gallery_mappings]} GalleryMappings"

    # 2. Destroy all Galleries
    puts "Destroying Galleries..."
    counts[:galleries] = Gallery.count
    Gallery.destroy_all
    puts "✓ Destroyed #{counts[:galleries]} Galleries"

    # 3. Destroy all Sales
    puts "Destroying Sales..."
    counts[:sales] = Sale.count
    Sale.destroy_all
    puts "✓ Destroyed #{counts[:sales]} Sales"

    # 4. Destroy all Appointments
    puts "Destroying PhotoShoots..."
    counts[:photo_shoots] = PhotoShoot.count
    PhotoShoot.destroy_all
    puts "✓ Destroyed #{counts[:photo_shoots]} PhotoShoots"

    # 4. Destroy all Appointments
    puts "Destroying Appointments..."
    counts[:appointments] = Appointment.count
    Appointment.destroy_all
    puts "✓ Destroyed #{counts[:appointments]} Appointments"

    # 5. Destroy all Customers
    puts "Destroying Customers..."
    counts[:customers] = Customer.count
    Customer.destroy_all
    puts "✓ Destroyed #{counts[:customers]} Customers"

    # Summary
    puts "\nReset completed successfully!"
    puts "Summary of destroyed records:"
    puts "  - GalleryMappings: #{counts[:gallery_mappings]}"
    puts "  - Galleries: #{counts[:galleries]}"
    puts "  - Sales: #{counts[:sales]}"
    puts "  - Appointments: #{counts[:appointments]}"
    puts "  - Customers: #{counts[:customers]}"
    puts "Total: #{counts.values.sum} records"
  end
end
